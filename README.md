# coalDB

coalDB is a stand-alone application to the PrIMe Coal Database.

## Motivation

Ease of access to the PrIMe Coal Database. Allows users to easily discover, visualize coal data. This application acts as an easy pathway from the PrIMe Coal Database to the bound-to-bound data collaboration(B2B-DC) data analysis.

## Requirements

**ReactionLab** toolbox is required. 

## Known Issues
* When there is uncertainty in the measurements in the x-axis, cannot plot error bars in that direction(errorbar() assumes its in the y-E, y+E)

* Issue with legend. When 2 experiments with different properties are plotted. It will incorrectly display the name in legend.

## Future Changes

* Sort by columns (difficult)
* Show only particular ranges of values -- is there an easy way?

* Filtering done through search of XML (not table results) search BY ____ uimenulist of sections/attributes to search by. Any field can be used
* Introduction to add to DB -- easy way to create xml & upload. hdf works. h5 does not!

## License

Copyright 2016, Jim Oreluk. 

Licensed under the [Apache License](LICENSE.md)
