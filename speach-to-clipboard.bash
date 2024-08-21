rec() {
  # Versie-informatie
  VERSION="1.1.1"

  # Controleer of benodigde tools zijn geïnstalleerd
  for cmd in ffmpeg sox whisper xclip sed; do
    if ! command -v $cmd &>/dev/null; then
      echo "$cmd is niet geïnstalleerd. Installeer het eerst."
      return 1
    fi
  done

  # Standaardwaarden
  language="nl"
  style=""
  prefix_language="nl"
  styles_dir="$HOME/Prompts/styles"

  # Verwerk command-line opties
  while [[ $# -gt 0 ]]; do
    case $1 in
    -E)
      language="en"
      shift
      ;;
    -N)
      language="nl"
      shift
      ;;
    --style)
      if [[ -n "$2" && "$2" != -* ]]; then
        style="$2"
        shift 2
      else
        echo "Fout: --style vereist een argument." >&2
        return 1
      fi
      ;;
    --prefix-lang)
      if [[ -n "$2" && "$2" != -* ]]; then
        prefix_language="$2"
        shift 2
      else
        echo "Fout: --prefix-lang vereist een argument (nl of en)." >&2
        return 1
      fi
      ;;
    --version)
      echo "rec versie $VERSION"
      return 0
      ;;
    *)
      echo "Onbekende optie: $1" >&2
      return 1
      ;;
    esac
  done

  echo "rec versie $VERSION"

  # Maak de ~/Prompts en ~/Prompts/styles directories aan als deze nog niet bestaan
  mkdir -p "$styles_dir"

  # Genereer een unieke bestandsnaam op basis van datum en tijd
  timestamp=$(date +"%Y%m%d_%H%M%S")
  output_file=~/Prompts/opname_${timestamp}.txt

  # Start opname
  echo "Start opname in ${language}... Druk op CTRL-C om te stoppen."
  filename=$(mktemp --suffix=.wav)
  sox -d $filename

  # Controleer of het bestand is aangemaakt en niet leeg is
  if [ ! -s "$filename" ]; then
    echo "Fout: Audio-bestand is leeg of niet aangemaakt."
    rm "$filename"
    return 1
  fi

  # Converteer audio naar tekst met Whisper
  echo "Omzetten van audio naar tekst met Whisper..."
  full_output=$(whisper "$filename" --model base --language $language 2>&1)

  # Extraheer alleen de herkende tekst uit de output
  recorded_text=$(echo "$full_output" | sed -n '/\[00:/,/]/p' | sed 's/\[.*\] *//g' | tr -d '\n')

  echo "Herkende tekst: $recorded_text"

  # Voeg vooraf gedefinieerde tekst toe
  final_text=""

  # Voeg stijl-specifieke tekst toe als deze is opgegeven
  if [ -n "$style" ]; then
    style_dir="$styles_dir/$style"
    prefix_file="$style_dir/prefix_${prefix_language}.txt"
    echo "Zoeken naar prefix bestand: $prefix_file"
    if [ -f "$prefix_file" ]; then
      echo "Prefix bestand gevonden. Inhoud:"
      cat "$prefix_file"
      prefix_text=$(cat "$prefix_file")
      final_text="${prefix_text}\n\n${recorded_text}"
      echo "Finale tekst met prefix: $final_text"
    else
      echo "Waarschuwing: Prefix bestand voor $style in $prefix_language niet gevonden."
      final_text="${recorded_text}"
    fi
  else
    final_text="${recorded_text}"
  fi

  # Toon de volledige tekst
  echo "Volledige tekst:"
  echo -e "$final_text"

  # Sla de tekst op in het outputbestand
  echo -e "$final_text" >"$output_file"
  echo "Tekst opgeslagen in $output_file"

  # Kopieer tekst naar klembord
  echo -e "$final_text" | xclip -selection clipboard

  # Verifieer of de tekst is gekopieerd
  clipboard_content=$(xclip -selection clipboard -o)
  if [ "$clipboard_content" = "$final_text" ]; then
    echo "Tekst is succesvol gekopieerd naar het klembord."
  else
    echo "Fout: Tekst kon niet naar het klembord worden gekopieerd."
    echo "Clipboard inhoud: $clipboard_content"
    echo "Verwachte inhoud: $final_text"
  fi

  # Verwijder tijdelijk audiobestand
  rm "$filename"

  echo "Opname voltooid met rec versie $VERSION"
}