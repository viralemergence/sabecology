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

### `get_interactions` (maint. @tpoisot)

This part of the workflow does a very light and _likely wrong_ cleaning of virus
names, and merges this to the cleaned host names information It generates a file
in `data/network/`, under the artifact name `interactions_csv_file`.

It **requires** a succesful run of `find_hosts` in order to run.

The interactions are stored in `interactions.csv`, which is essentially the
found hosts taxonomy file returned by `find_hosts`, with a few columns removed,
and the cleaned virus name added. The columns are:

~~~
virus,accession,level,name,kingdom,kingdom_id,phylum,phylum_id,class,class_id,order,order_id,family,family_id,genus,genus_id,species,species_id
~~~

**Important note**: the virus names are cleaned by extracting the match of
`(\w+)vir(us|ales|idae|inae|ina)`, and then converting this to titlecase. This
begs for a dedicated workflow step to cleanup virus names.

## `network_structure` (maint. @tpoisot)

This part of the workflow performs the usual network analysis, and places the
results in `data/network/`, under the artifact name `network_structure`.

It **requires** a succesful run of `get_interactions` in order to run.

The interactions are stored in `XXX_level_network_metrics.csv`, where `XXX` can
be either `genus` or `species`, to represent different aggregations of the
hosts. The columns are

~~~
species,degree,community,within_module_z,participation_coefficient
~~~

The last two colums are the components of the usual functional clustering in
networks, and can be used to classify nodes as either hubs, connectors,
peripherals, *etc*.

## Sharing artifacts between jobs

**TODO**