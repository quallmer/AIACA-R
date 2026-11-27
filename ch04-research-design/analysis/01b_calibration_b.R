# Step 1, second part. Divide the transcription of Calibration Set B into
# sentences.
#
# Calibration Set B is a political speech printed in the manual and is not in
# Pang and Ring's files. Its transcription has one paragraph per line, with
# lines marking the pages; a paragraph that continues over a page break ends
# in " [continues]". Nothing here reads the expert scoring.
#
# The rule. A sentence ends at a full stop, question mark, or exclamation mark
# (with any closing quotation mark) that is followed by two or more spaces or
# by the end of a paragraph. The typescript puts two spaces after a sentence
# and one after an abbreviation, and the transcription keeps that. A colon or
# semicolon does not end a sentence, so a sentence can run across a paragraph
# break. A spaced ellipsis (". . .") does not end one either.

source("R/setup.R")

paragraphs <- tibble(
  line = read_lines(file.path(runs_dir, "calibration_b_transcription.txt"))
) |>
  filter(str_squish(line) != "") |>
  mutate(
    pdf_page = parse_number(if_else(
      str_detect(line, "^=== PDF page"),
      line,
      NA
    ))
  ) |>
  fill(pdf_page) |>
  filter(!str_detect(line, "^=== PDF page")) |>
  mutate(
    continues = str_detect(line, " \\[continues\\]$"),
    line = str_remove(line, " \\[continues\\]$"),
    paragraph = cumsum(lag(!continues, default = TRUE))
  ) |>
  summarise(
    pdf_page = first(pdf_page),
    text = str_flatten(line, "  "),
    .by = paragraph
  )

sentences <- paragraphs |>
  mutate(
    text = text |>
      str_replace_all("\\. \\. \\.", "<ELLIPSIS>") |>
      str_replace_all("([.?!][\"']*) {2,}", "\\1<END>") |>
      str_replace_all(" {2,}", " ")
  ) |>
  separate_longer_delim(text, "<END>") |>
  mutate(text = str_squish(text)) |>
  filter(text != "") |>
  # a piece that does not end a sentence runs on into the next paragraph
  mutate(
    sentence = cumsum(lag(str_detect(text, "[.?!][\"']*$"), default = TRUE))
  ) |>
  summarise(
    paragraph = first(paragraph),
    pdf_page = first(pdf_page),
    text = str_flatten(text, " "),
    .by = sentence
  ) |>
  mutate(text = str_replace_all(text, "<ELLIPSIS>", ". . ."))

# Coded once, so the file that was coded is not overwritten.
sentence_file <- file.path(runs_dir, "calibration_b_sentences.csv")
if (!file.exists(sentence_file)) {
  write_csv(sentences, sentence_file)
}

sentences |>
  summarise(
    paragraphs = nrow(paragraphs),
    sentences = n(),
    words = sum(str_count(text, "\\S+"))
  )
