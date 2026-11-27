# Step 6, second part. The expert scoring of the calibration sets.
#
# The manual seals the expert scoring of Calibration Sets A and B in a
# separate file. It was opened only after the specification was frozen and
# every coder's output on both sets was saved. The scoring was then
# transcribed by AI assistants, twice and independently, as one record for each scored
# image: its motive, the phrases the expert underlines, and any remark beside
# the label.
#
# This script places each image in the sentences it may be scored in. The
# expert often marks one image across two or more phrases ("either phrase"),
# or notes that the next sentence could have been scored instead, so an image
# can have more than one admissible sentence. It is still one image.

source("R/setup.R")

transcription <- read_csv(
  file.path(runs_dir, "calibration_key_transcription.csv"),
  show_col_types = FALSE
) |>
  filter(image > 0)

sentences <- bind_rows(
  read_stories() |> filter(set == "CA") |> select(doc, sentence, text),
  read_speech() |> select(doc, sentence, text)
)

phrases <- transcription |>
  separate_longer_delim(phrases, " | ") |>
  mutate(
    sentence = locate_phrases(phrases, sentences$text[sentences$doc == doc[1]]),
    .by = doc
  )

# Every phrase has to be found. A phrase that is not is a slip in the
# transcription of the key or of the text, to be looked up on the page.
filter(phrases, is.na(sentence))

key <- phrases |>
  summarise(
    sentences = list(sort(unique(c(
      sentence,
      if (first(also_next_sentence)) max(sentence) + 1
    )))),
    phrases = str_flatten(phrases, " | "),
    .by = c(doc, image, motive, remark)
  )

key |>
  mutate(sentences = map_chr(sentences, str_flatten, "|")) |>
  write_csv(file.path(runs_dir, "calibration_key.csv"))

# Scored images by set and motive.
key |>
  count(set = str_remove(doc, "[0-9]+$"), motive) |>
  pivot_wider(names_from = motive, values_from = n)
