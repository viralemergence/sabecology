# Workflows

## A quick introduction

Workflows allow to chain together series of jobs, and to run them on certain
events. The workflow is currently running on every pull request, on every push
to `master`, and then additionally every day at 6am (but don't ask which
timezone). Workflows are [documented on the GitHub help][workflow_help].

[workflow_help]: https://help.github.com/en/actions

Every *workflow* is a series of *jobs*, and every job starts a virtual machine
which can be fully customized, and can both *read* and *create* files. For this
reason, it is useful to think of every job as a sort of blackbox, where the
inputs files (either the products of previous steps, or raw data from the repo),
and the output is a flat file that can be used downstream. The current
components of the workflow are documented below.

Outputs (called *artifacts*) can be shared *between jobs in a workflow*, but not
*across workflows*. Nevertheless, different projects can have different
worflows, and therefore function independently. Jobs in a workflow only start
when their dependencies are built, but job with different dependencies can run
in parallel.

Overall, working with a workflow allows each of us to contribute to the codebase
using the languages and packages of our choice, and also avoids the need to
store all of the intermediate data products in the git repo. The current state
of the workflows can be viewed from the repo's [Actions page][actions].

[actions]: https://github.com/ViromeNet/sabecology/actions

## Current workflow components

This section documents the current workflow stages, the required steps, and the
objects that are written. It is recommended to use the first block as a template
when adding a step to the workflow.

### `find_hosts` (maint. @tpoisot)

This part of the workflow matches host names to GBIF taxa, using information in
the raw Excel file *and* in the `data/extra` file with hostnames. It generates
two files in `data/hostnames/`, under the artifact name `hostnames_csv_files`.

The first file is `found.csv`, which has one line for every host name that
was found in GBIF, as well as information on the type of match and the
confidence in the match. Lines with a low confidence are good candidates for
manual cleaning. The columns in the first file are

~~~
original,match,confidence,level,name,kingdom,kingdom_id,phylum,phylum_id,class,class_id,order,order_id,family,family_id,genus,genus_id,species,species_id
~~~

The second file is `unknown.csv`, and it has a string that was not matched to a species name, and the number of sequences for which this string was the host. Lines with a high count are useful candidates for manual cleaning. The columns for the second file are:

~~~
string,count
~~~

## Sharing artifacts between jobs

**TODO**