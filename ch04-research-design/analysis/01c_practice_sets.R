# Step 1, third part. Divide the transcription of the manual's practice Sets
# G to J into documents and sentences.
#
# These four sets are printed in the manual with expert scoring and are not in
# Pang and Ring's files. They were transcribed on 22 November 2026 to serve
# as a fresh test. Nothing here reads their expert scoring, which
# stays unopened until a specification is frozen and every declared coder has
# saved its output on them.
#
#   Set G   30 stories told aloud in an interview. The subject's turns begin
#           "S:". The interviewer's turns are in brackets, "[I: ...]", and
#           the manual says they are not scored. A document is one story.
#   Sets H, I, J   one political speech each. A document is one speech.
#
# The transcription has one line for each turn or paragraph, with lines
# marking the pages.
#
# The rule for a sentence. It ends at a full stop, question mark, or
# exclamation mark (with any closing quotation mark or bracket) that is
# followed by a space and a capital letter, or by the end of a turn or
# paragraph. Three dots are a pause and do not end a sentence. Four dots are
# a pause with a full stop and do. One initial, in a name, is protected.

source("R/setup.R")

lines <- tibble(
  line = read_lines(file.path(runs_dir, "practice_GJ_transcription.txt"))
) |>
  mutate(
    pdf_page = parse_number(if_else(
      str_detect(line, "^=== PDF page"),
      line,
      NA
    ))
  ) |>
  fill(pdf_page) |>
  filter(!str_detect(line, "^=== PDF page"), str_squish(line) != "") |>
  mutate(
    line = str_squish(line),
    set = case_when(
      pdf_page <= 103 ~ "G",
      pdf_page <= 110 ~ "H",
      pdf_page <= 116 ~ "I",
      .default = "J"
    )
  )

split_sentences <- function(text) {
  text |>
    str_replace_all("John F\\. Kennedy", "John F<DOT> Kennedy") |>
    str_replace_all("(?<!\\.)\\.{3}(?!\\.)", "<PAUSE>") |>
    str_replace_all("([.?!][\"')\\]]*) (?=[\"'(\\[]*[A-Z])", "\\1<END>") |>
    str_replace_all("<PAUSE>", "...") |>
    str_replace_all("<DOT>", ".") |>
    str_split("<END>")
}

# Set G: the stories ----------------------------------------------------------

# A line with no label continues the turn before it, across a page break.
turns <- lines |>
  filter(set == "G", line != "(story continues on next page)") |>
  mutate(
    doc = if_else(
      str_detect(line, "^G-[0-9]+$"),
      str_remove(line, "-"),
      NA
    )
  ) |>
  fill(doc) |>
  filter(!is.na(doc), !str_detect(line, "^G-[0-9]+$")) |>
  mutate(
    speaker = case_when(
      str_detect(line, "^S:") ~ "subject",
      str_detect(line, "^\\[I:") ~ "interviewer"
    ),
    turn = cumsum(!is.na(speaker)),
    .by = doc
  ) |>
  summarise(
    speaker = first(speaker),
    pdf_page = first(pdf_page),
    text = str_flatten(line, " "),
    .by = c(set, doc, turn)
  )

# Every story should open with a labelled turn.
filter(turns, is.na(speaker))

stories <- turns |>
  filter(speaker == "subject") |>
  mutate(text = split_sentences(str_remove(text, "^S:\\s*"))) |>
  unnest(text) |>
  mutate(text = str_squish(text)) |>
  filter(str_detect(text, "[A-Za-z]")) |>
  mutate(sentence = row_number(), .by = doc)

# Sets H to J: the speeches ---------------------------------------------------

# A paragraph that runs over a page break is marked at both ends.
paragraphs <- lines |>
  filter(
    set != "G",
    !str_detect(line, "^(Practice )?Set [HIJ]$|^\\(Political Speeches\\)$")
  ) |>
  mutate(
    continues = lead(line, default = "") == "<<continues>>",
    .by = set
  ) |>
  filter(!line %in% c("<<continues>>", "<<continued>>")) |>
  mutate(
    paragraph = cumsum(lag(!continues, default = TRUE)),
    .by = set
  ) |>
  summarise(
    pdf_page = first(pdf_page),
    text = str_flatten(line, " "),
    .by = c(set, paragraph)
  )

# A paragraph that does not end a sentence runs on into the next one.
speeches <- paragraphs |>
  mutate(doc = set, text = split_sentences(text)) |>
  unnest(text) |>
  mutate(text = str_squish(text)) |>
  filter(text != "") |>
  mutate(
    sentence = cumsum(lag(
      str_detect(text, "[.?!][\"')\\]]*$"),
      default = TRUE
    )),
    .by = doc
  ) |>
  summarise(
    paragraph = first(paragraph),
    pdf_page = first(pdf_page),
    text = str_flatten(text, " "),
    .by = c(set, doc, sentence)
  )

# Together --------------------------------------------------------------------

sentences <- bind_rows(stories, speeches) |>
  select(set, doc, turn, paragraph, sentence, pdf_page, text)

# Written once, so that the file that is coded is not overwritten.
sentence_file <- file.path(runs_dir, "practice_GJ_sentences.csv")
if (!file.exists(sentence_file)) {
  write_csv(sentences, sentence_file)
}

sentences |>
  summarise(
    documents = n_distinct(doc),
    sentences = n(),
    words = sum(str_count(text, "\\S+")),
    longest = max(str_count(text, "\\S+")),
    .by = set
  )

# What the subject's sentences leave out: the interviewer's turns.
turns |>
  count(speaker)
