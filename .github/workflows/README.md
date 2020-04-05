# The Workflow

Everything happens in `MetadataCleaning.yml` - the different bits of the
workflow should be jobs with clear names, so we can indicate which depends on
which. The way to pass artifacts between jobs is to upload/download them - note
that all collected artifacts can be downloaded at the end of the workflow (or
pushed to `gh-pages` if we want to go this way).

Every job can install its own programming language, dependencies, *etc*. Working
with jobs is a Good Idea because we can easily identify the parts that are
crashing, and we can also assign people to various components of the worflow.
Importantly, this means that most of us will not need to understand the whole
process, as long as have an idea of what the files that are generated mean.