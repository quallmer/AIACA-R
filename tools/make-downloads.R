# Runs after every render (see `post-render` in _quarto.yml).
#
# For each chapter folder it writes, into the rendered site:
#   - one script for each numbered tutorial page, holding that page's code;
#   - one archive of the chapter's code: those scripts, the chapter's R/ and
#     codebook/ folders, and get-data.R.
# Nothing is executed, and nothing is written to the repository.

site <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", unset = "_site")
chapters <- list.files(".", pattern = "^ch[0-9]{2}-")
chapters <- chapters[dir.exists(chapters)]

for (chapter in chapters) {
  out <- file.path(site, chapter)
  if (!dir.exists(out)) {
    next
  }
  pages <- list.files(chapter, pattern = "^[0-9].*\\.qmd$")

  staging <- file.path(tempdir(), chapter)
  unlink(staging, recursive = TRUE)
  dir.create(staging)

  for (page in pages) {
    script <- sub("\\.qmd$", ".R", page)
    knitr::purl(
      file.path(chapter, page),
      output = file.path(staging, script),
      documentation = 0,
      quiet = TRUE
    )
    file.copy(file.path(staging, script), out, overwrite = TRUE)
  }

  for (extra in c("R", "codebook", "get-data.R")) {
    from <- file.path(chapter, extra)
    if (file.exists(from)) {
      file.copy(from, staging, recursive = TRUE)
      file.copy(from, out, recursive = TRUE)
    }
  }

  if (length(list.files(staging))) {
    archive <- normalizePath(
      file.path(out, paste0(substr(chapter, 1, 4), "-code.zip")),
      mustWork = FALSE
    )
    unlink(archive)
    project <- setwd(dirname(staging))
    utils::zip(archive, files = chapter, flags = "-rq")
    setwd(project)
  }
}
