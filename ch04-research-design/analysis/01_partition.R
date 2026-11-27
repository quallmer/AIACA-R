# Step 1. The partition, made before any model is run.
#
# Every document is assigned once, to development or to reserve, and every
# later script reads the table written here. It holds identifiers and counts
# only. No text and no label is kept.
#
#   development           practice sets PA to PF
#   reserved by source    Calibration Set A (stories CA1 to CA30) and
#                         Calibration Set B (a speech in the manual)
#   reserved by us        the 18 email writers, split by writer into a first
#                         test and a hold-out, balanced on Misbehaver_status.
#                         The hold-out is touched only if the specification is
#                         revised after the first test.

source("R/setup.R")

stories <- read_excel(file.path(data_dir, "UD1_sentences.xlsx")) |>
  count(unit = Subj_story, name = "n_sentences") |>
  mutate(
    source = "UD1",
    set = str_remove(unit, "[0-9]+$"),
    role = if_else(set == "CA", "reserved_by_source", "development"),
    n_documents = 1,
    basis = if_else(
      set == "CA",
      "manual: Calibration Set A",
      "manual: practice set"
    )
  ) |>
  arrange(set == "CA", set, parse_number(unit))

speech <- tibble(
  source = "manual",
  set = "CB",
  unit = "CB",
  role = "reserved_by_source",
  n_documents = 1,
  n_sentences = NA,
  basis = "manual: Calibration Set B (speech; to be transcribed)"
)

writers <- read_excel(file.path(data_dir, "UD2_sentences.xlsx")) |>
  summarise(
    n_documents = n_distinct(Filename),
    n_sentences = n(),
    .by = c(Person, Misbehaver_status)
  ) |>
  arrange(Misbehaver_status, Person)

# Nine writers in each stratum: five and four go to the first test.
seed <- 20261121
set.seed(seed)
first_test <- c(
  sample(writers$Person[writers$Misbehaver_status == 0], 5),
  sample(writers$Person[writers$Misbehaver_status == 1], 4)
)

emails <- writers |>
  transmute(
    source = "UD2",
    set = "UD2",
    unit = Person,
    role = if_else(
      unit %in% first_test,
      "reserved_first_test",
      "reserved_holdout"
    ),
    n_documents,
    n_sentences,
    basis = str_c(
      "split by writer, seed ",
      seed,
      ", Misbehaver_status ",
      Misbehaver_status
    )
  )

partition <- bind_rows(stories, speech, emails) |>
  select(source, set, unit, role, n_documents, n_sentences, basis)

# The table has to predate every model run, so it is written once.
partition_file <- file.path(runs_dir, "partition.csv")
if (!file.exists(partition_file)) {
  write_csv(partition, partition_file)
}

partition |>
  summarise(
    units = n(),
    documents = sum(n_documents),
    sentences = sum(n_sentences),
    .by = c(source, set, role)
  )
