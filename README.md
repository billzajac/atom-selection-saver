# selection-saver package

A package to allow for quick saving of meta-data around a selection.

![A screenshot of your theme](https://f.cloud.github.com/assets/69169/2289498/4c3cb0ec-a009-11e3-8dbd-077ee11741e5.gif)

Install
----------
* Install Atom
    * https://atom.io/
    * You may also need to install the command line tools
        * http://stackoverflow.com/questions/22390709/open-atom-editor-from-command-line

* Install this package
```
mkdir -p ~/.atom/packages
cd !$
git clone https://github.com/billzajac/selection-saver
```

* Add required package
```
npm install event-stream
```

Usage
----------
* copy the manifest file to the base directory of it's contents
    * in other words, if you are in the directory with avagit, copy your manifest file there
```
atom YOUR_MANIFEST_FILE
```

* Start the Selection Saver
    * ctrl-alt-s

* Page Down
    * space

* Page Up
    * b

* Select some text and hit the following to log
    * z

* Close the window (go to the next file)
    * q or ctrl-w

* Re-Open the previous file
    * w
        * NOTES:
            * This will only go back **one** file
            * Once you have finished with it, press q to close that tab and return to where you were

* Quit
    * To quit, first close the log tab on the bottom, then the top tab

* Once you are done with the whole manifest, close Atom

* NOTE: Atom will save a file with a list of completed files as YOUR_MANIFEST_FILE.completed_files

Redact Syntax Highlighting
----------

* Install the following package
    * https://github.com/execjosh/atom-file-types
    * Atom -> Preferences -> Packages -> + Install "file-types" (Click Packages) -> Install
* Update your config
    * Atom -> Config (Add the following to the end)

```
  "file-types":
    "\\.*": "source.redact"
  "editor":
    "softWrap": true
```

* Close the window with ctrl-w and restart Atom
