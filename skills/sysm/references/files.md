# sysm Files & Data Reference — finder, tags, spotlight, disk, pdf, image, vision, language, keychain

## finder

### finder open
`sysm finder open <path>`
- Opens file or folder in Finder

### finder reveal
`sysm finder reveal <path>`
- Reveals and selects item in Finder

### finder info
`sysm finder info <path> [--json]`

### finder trash
`sysm finder trash <path> [--force]`

---

## tags
*Finder tags (macOS extended attributes).*

Tags on a symbolic link belong to the link itself, as they do in Finder. The
file it points at is left untouched.

### tags list
`sysm tags list <path> [--json]`

### tags add
`sysm tags add <path> --tag <tag> [--color <color>]`
- `--color` Name or number: none (0), gray (1), green (2), purple (3),
  blue (4), yellow (5), red (6), orange (7). Default: none

### tags remove
`sysm tags remove <path> --tag <tag>`

### tags set
`sysm tags set <path> --tags <tags>`
- `--tags` Comma-separated, each with an optional color name or number:
  'work,important' or 'work:blue,important:6'
- Replaces the file's tags with exactly this set

### tags find
`sysm tags find <tag> [--scope <dir>] [--limit <n>] [--json]`
- `--scope` Restrict search to directory

---

## spotlight

### spotlight search
`sysm spotlight search <query> [--scope <dir>] [--limit <n>] [--json]`

### spotlight kind
`sysm spotlight kind <kind> [--scope <dir>] [--limit <n>] [--json]`
- `<kind>` pdf, image, video, audio, document, folder, application, archive, presentation, spreadsheet

### spotlight modified
`sysm spotlight modified <days> [--scope <dir>] [--limit <n>] [--json]`
- Files modified in the last N days

### spotlight metadata
`sysm spotlight metadata <path> [--json]`

---

## disk

### disk list
`sysm disk list [--json]`

### disk info
`sysm disk info [<path>] [--json]`
- `<path>` Mount point (default: /)

### disk usage
`sysm disk usage <path> [--json]`

### disk eject
`sysm disk eject <name>`
- `<name>` Volume name

---

## pdf
*All PDF operations use Apple's PDFKit framework.*

### pdf info
`sysm pdf info <input> [--json]`

### pdf text
`sysm pdf text <input> [--page <n>] [--json]`
- `--page` 1-based page number; omit for all pages

### pdf search
`sysm pdf search <input> <query> [--case-sensitive] [--json]`

### pdf pages
`sysm pdf pages <input> [--json]`

### pdf thumbnail
`sysm pdf thumbnail <input> --page <n> --output <path> [--size <pixels>]`
- `--size` Max dimension (default: 256)

### pdf merge
`sysm pdf merge <file1> <file2> ... --output <output>`

### pdf split
`sysm pdf split <input> --pages <range> --output <output>`
- `--pages` Range: '1-3', '2-5'

### pdf rotate
`sysm pdf rotate <input> --pages <pages> --angle <angle> --output <output>`
- `--pages` Comma-separated: '1,3,5'
- `--angle` 0, 90, 180, 270

### pdf encrypt
`sysm pdf encrypt <input> --owner-password <pwd> [--user-password <pwd>] --output <output>`

### pdf decrypt
`sysm pdf decrypt <input> --password <pwd> --output <output>`

### pdf compress
`sysm pdf compress <input> --output <output>`

### pdf ocr
`sysm pdf ocr <input> --output <output>`
- Creates searchable PDF from scanned document

### pdf image-to-pdf
`sysm pdf image-to-pdf <img1> <img2> ... --output <output>`

### pdf watermark
`sysm pdf watermark <input> --text <text> [--font-size <n>] [--opacity <0.0-1.0>] [--angle <degrees>] --output <output>`
- Defaults: font-size=48, opacity=0.3, angle=-45

### pdf annotate
`sysm pdf annotate <input> --page <n> [--type <type>] --text <text> --x <x> --y <y> --output <output>`
- `--type` note, text (default: note)

### pdf annotations
`sysm pdf annotations <input> [--page <n>] [--json]`

### pdf outline
`sysm pdf outline <input> [--json]`

### pdf permissions
`sysm pdf permissions <input> [--json]`

### pdf metadata show
`sysm pdf metadata show <input> [--json]`

### pdf metadata set
`sysm pdf metadata set <input> [options] --output <output>`
*(use `sysm pdf metadata set --help` for all fields)*

---

## image
*Image processing via CoreImage/ImageIO.*

### image resize
`sysm image resize <input> --output <output> [--width <px>] [--height <px>]`
- Provide one or both dimensions; maintains aspect ratio if only one given

### image convert
`sysm image convert <input> --output <output> --format <format>`
- `--format` png, jpeg, tiff, heif

### image ocr
`sysm image ocr <input> [--json]`
- Extracts text from image using Vision framework

### image metadata
`sysm image metadata <input> [--json]`

### image thumbnail
`sysm image thumbnail <input> --output <output> [--size <px>]`
- `--size` Max dimension (default: 256)

---

## vision
*Apple Vision framework — on-device computer vision.*

### vision barcode
`sysm vision barcode <image> [--json]`
- Detects and decodes QR codes, barcodes, etc.

### vision faces
`sysm vision faces <image> [--json]`
- Detects face bounding boxes and landmarks

### vision classify
`sysm vision classify <image> [--limit <n>] [--json]`
- Image classification (labels + confidence scores)
- `--limit` Max results (default: 10)

### vision rectangles
`sysm vision rectangles <image> [--json]`
- Detects rectangular regions (documents, screens)

---

## language
*Natural language processing via the Natural Language framework — on-device.*

Every subcommand takes the text as an argument or reads it from a file with
`--file`, and supports `--json`.

### language detect
`sysm language detect [<text>] [--file <file>] [--json]`
- Reports the dominant language of the text

### language tokenize
`sysm language tokenize [<text>] [--file <file>] [--unit <unit>] [--json]`
- `--unit` word, sentence, paragraph (default: word)

### language entities
`sysm language entities [<text>] [--file <file>] [--json]`
- Extracts named entities: people, places, organizations

### language tag
`sysm language tag [<text>] [--file <file>] [--json]`
- Part-of-speech tagging

### language lemma
`sysm language lemma [<text>] [--file <file>] [--json]`
- Reduces each word to its dictionary form

---

## keychain
*macOS Keychain via Security framework.*

### keychain get
`sysm keychain get <service> <account> [--json]`
- Returns the password/secret for service+account

### keychain set
`sysm keychain set <service> <account> --value <value> [--label <label>] [--json]`

### keychain delete
`sysm keychain delete <service> <account> [--json]`

### keychain list
`sysm keychain list [--service <service>] [--json]`
- Lists items (does NOT return secret values)

### keychain search
`sysm keychain search <query> [--json]`
- Matches service, account, or label
