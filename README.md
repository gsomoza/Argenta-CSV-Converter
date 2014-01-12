Argenta CSV Converter
=====================

Argenta uses a CSV format that is not supported by many US applications, such as Quicken. This tool automates part of
the process of importing Argenta CSV files into such applications.

Features
---------
1. Remove the first line (header).
2. Unify all CSV files within a folder. Argenta allows you to download only 40 transactions at a time.
3. Convert the separators and decimal symbols.

Usage
-----
`ruby argenta-cli.rb [options] input_files

To unify all files within a folder simply pass a folder as input. You can also pass multiple files by separating them
with spaces.

Options
-------
* `--keep-header`: Don't automatically remove the first line from the output (header). Only the first header will remain
available at the top of the output. The rest of the headers will still be discarded.

