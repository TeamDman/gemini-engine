<div align="center">

# Gemini Engine

<img height=400 src="https://cards.scryfall.io/large/front/2/e/2e03e05b-011b-4695-950b-98dd7643b8a0.jpg?1562636055">

Mine
[![Discord](https://img.shields.io/discord/967118679370264627.svg?colorB=7289DA&logo=data:image/png)](https://discord.gg/5mbUY3mu6m)

Google Developer Community
[![Discord](https://img.shields.io/discord/1009525727504384150.svg?colorB=7289DA&logo=data:image/png)](https://discord.gg/google-dev-community)

</div>

A collection of scripts I'm using to interact with the Gemini 1.5 Pro API.

## Dependencies

This project expects the following commands to be available for full functionality:

- `pwsh`
- `fzf`
- `hx`
- `sqlite3`
- `zoxide`
- `rg`
- `eza`
- `yt-dlp`
- `cargo`
- `python`
- `code`

## Using Gemini

[FAQ](https://docs.google.com/document/d/1WBVc5W6PZvgaHLV43UGSrtwHqUmofPT0K0oHuNd7GHA/edit#heading=h.j6pr32lsg1rf)

[Docs](https://ai.google.dev/api/python/google/ai/generativelanguage/GenerativeServiceClient#generate_content)

### Feedback

Visit https://aistudio.google.com/app/prompts/new_chat and use the three dots in the top right to submit feedback to Google.

### Examples

https://github.com/google-gemini/gemini-api-cookbook/tree/main/quickstarts

https://colab.research.google.com/github/google-gemini/gemini-api-cookbook/blob/main/preview/file-api/File_API.ipynb#scrollTo=IrPDYdQSKTg4

https://colab.research.google.com/github/google-gemini/gemini-api-cookbook/blob/main/preview/file-api/File_API_Video.ipynb

## Mimetypes

Sourced from https://www.iana.org/assignments/media-types/media-types.xhtml using

```javascript
copy(Array.from(document.querySelectorAll("td:nth-child(2)")).map(x => x.innerText).join("\n"))
```