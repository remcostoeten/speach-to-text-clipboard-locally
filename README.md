# Speech-to-Text Recording Function

This tool provides an advanced speech-to-text recording function with support for various styles and languages.

## TLDR

- Pip install whistle, homebrew or apt-get the remaining

Paste `.bash` function in your `.bashrc`or `.zshrc`

or in root here

```bash
echo 'if [ -f ~/speach-to-clipboard.bash ]; then . ~/speach-to-clipboard.bash; fi' >> ~/.bashrc
```

for `.zshrc`

```shell
echo 'if [ -f ~/speach-to-clipboard.bash ]; then source ~/speach-to-clipboard.bash; fi' >> ~/.zshrc
```

Reload shell and g2g

typ `rec -E` or `rec -N` for more accurate eng/dutch outcome.

`rec --help` for help...
`rec -E --style <~/Prompts/FOLDERNAME/.txt>` for prefixing the outcome which is handy to have project specs. Read more further.

MVP beta, still dutch, probablyy will forget but works on my machine xxx

## Installation

1. Ensure you have the following tools installed:

   - [ffmpeg](https://ffmpeg.org/download.html)
   - [sox](http://sox.sourceforge.net/)
   - [whisper](https://github.com/graphite-project/whisper)
   - [xclip](https://github.com/astrand/xclip)
   - [sed](https://www.gnu.org/software/sed/)
   - Install additional dependencies using apt:
     ```
     sudo apt update && sudo apt install -y ffmpeg sox xclip sed
     ```
   - Install Whisper using pip:
     ```
     pip install whisper
     ```

2. Create the necessary directories:

```bash
mkdir -p ~/Prompts/styles/frontend
```

3. Create a sample prefix file:

```bash
cat << EOF > ~/Prompts/styles/frontend/prefix_en.txt
As a frontend developer, I focus on:
- React and Next.js
- TypeScript
- Tailwind CSS
- State management
- Responsive design
EOF
```

4. Add the `rec` function to your `~/.bashrc` file:

```bash
cat << 'EOF' >> ~/.bashrc
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
EOF
```

5. Reload your `.bashrc` file:

```bash
source ~/.bashrc
```

## Usage

Use the `rec` function with various options:

```bash
rec [options]
```

For example:

```bash
rec -E --style frontend --prefix-lang en
```

For more information on available options, use:

```bash
rec --help
```
