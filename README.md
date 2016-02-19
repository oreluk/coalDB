# coalDB

coalDB is Stand-alone Interface to the PrIMe Coal Database

## Motivation

Why. 

## Requirements


## Known Issues
* When there is uncertainty in the measurements in the x-axis, cannot plot error bars in that direction(errorbar() assumes its in the y-E, y+E)

* Issue with legend. When 2 experiments with different properties are plotted. It will incorrectly display the name in legend.

## Future Changes

* Sort by columns, show only particular ranges of values

* Sort O2, Temperature by Greater than, less than, or equal to a numerical value. (should have a dropdown menu for these options)

* Filtering done through search of XML (not table results) search BY ____ uimenulist of sections/attributes to search by. Any field can be used

* Show datapoint tool tip over plots. (can this work for error bars?)


## License

Copyright 2016, Jim Oreluk. 

Licensed under the [Apache License](LICENSE.md)
