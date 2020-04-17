# Modeling project aims

## Sampling spatial and temporal

We likely can't do this until we have the full prevalence data, but can we get descriptors going?

## Link prediction bake-off

Methods we're likely to try, and who can implement them

- Han reservoir approach with BRTs (Becker, Han?, Dallas?)
- Plug and play (Dallas)
- BART from sequence-munging + host traits (Carlson, Albery? Who wants to do sequences with me?)
- Elmasri latent trait approach (Farrell)
- Linear filtering (Poisot)
- *k*-NN (Poisot)

## Zoonotic classification from sequence data

Goals

- adapt the Eng methods from influenza A
- try to classify zoonotic risk among coronaviruses, and maybe flaviviruses

Needs

- who can help wrangle the actual sequence data and process it into features?

## Spatial host-virus network

Coming up with a spatial host-virus network can be done either in a coarse way
like [the synthetic food web
paper](https://onlinelibrary.wiley.com/doi/full/10.1111/ecog.01941), or in a
slightly more fancy way like in [the Elton & Grinnell
paper](https://onlinelibrary.wiley.com/doi/10.1111/ecog.04006). Long story
short, can we map some properties of the network over space? The ingredients for
this are (i) species distributions and (ii) a network, possibly augmented by
inferred links. I feel like this can go a long way towards a map of spillover
risk?
