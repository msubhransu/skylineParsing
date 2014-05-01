## Parsing World's Skylines with Shape Constrained MRFs

Created by Subhransu Maji

### Introduction

Shape constrained MRFs are desined to exploit the tiered structure and the rectangular shapes of the builings in typical skyline images to enable faster and more accurate labelling. We are also releasing a skyline-12 dataset consisting of 120 high resolution images from 12 different cities. Each image contains labels of the individual buildings for benchmarking. The images are split into training, validation and test set for evaluation purposes.

The images were collected from [Flickr](www.flick.com) that were shared under creative commons licence.

### Citing this work

If you find the code and the dataset useful in your research, please consider citing:

    @inproceedings{tonge14CVPR,
        Author = {Rashmi Tonge, Subhransu Maji, and C.V. Jawahar},
        Title = {Parsing World's Skylines with Shape Constrained MRFs},
        Booktitle = {Computer Vision and Pattern Recognition},
        Year = {2014}
    }

### License

The code is released under the simplified BSD License (refer to the
LICENSE file for details).

### Installation

Prerequisites:

* MATLAB 2011a (or equivalent)
* g++ compiler (note: clang complier also works. see `compile.m`)
* `VLFEAT` [http://www.vlfeat.org/](http://www.vlfeat.org)
* A machine with 2GB+ of memory

Here are the steps for installation:

* Clone the git repository into your local directory
* Download the [skyline-12 dataset](http://ttic.uchicago.edu/~smaji/projects/data/skyline12.tar.gz)
* Set the paths. In the `skylineConfig.m` file you should change the path variables to reflect the location of the downloaded data and the `VLFEAT` directory 
* Run `startup.m`. You should see a message "Startup done".
* Run `compile.m`. This compiles all the MEX files needed for the code to run. You are all set. 

### Running the demos
In the main directory there are two demo files:

* `demoAnno.m`: This will load the annotations for the city of Chicago and display them in an interactive manner. Press `h` key for help. The code aldo contains other examples such as how to display all annotations, or those in the train set.

* `demoParse.m`: This will load an image and run various algorithms for parsing. The code also displays the intermediate steps of parsing, evaluates the resulting parse in terms of mean average overlap `MAO` scores (described in the paper). 

### Evaluation

To evaluate on a `imageSet={train, val, test}`, run `evalImageSet(conf, anno, imageSet)`. This will run all the methods on the `imageSet` and return the `MAO` scores for all the methods. This should reproduce the results in the paper, as listed below. The run times are on a Intel CPU @ 3.20GHz desktop.

Method         | MAO 		   | Running time
-------------- |:------------:|:------------:
Unary          | 54.5%        | n/a
Standard MRF   | 62.3% 		   | 69.5s
Tiered MRF 	   | 59.4%  	   | 7.5s
Rectangle MRF  |62.0% 		   | 5.5s
Reﬁned MRF     | 63.4%        | 9.2s

**Note**: minor differences might arise due to randomization in k-means

### Other notes

The `skylineConfig.m` has all the parameters for running the code. For example you can turn off the display by setting `conf.display=false`. If you want to save the output of the `rectangleMRF.m` as a .gif file, you can do so by setting `conf.gif=true`.

For speed the image is scaled down if the maximum dimension of the image is greater than `conf.param.image.maxDim=2000`. You could run the code faster by lowering this value. The parsing parameters are no longer optimal if this is changed, but in my experience the `rectangleMRF` and `standardMRF` work fine for a range of values of `maxDim`.
