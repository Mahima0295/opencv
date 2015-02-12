### OpenCV: Open Source Computer Vision Library

[![Gittip](http://img.shields.io/gittip/OpenCV.png)](https://www.gittip.com/OpenCV/)

#### Build notes

1. You might need to install this if you haven’t already: http://www.microsoft.com/en-US/download/details.aspx?id=40784
2. Set ```OPENCV_TEST_DATA_PATH``` environment variable to location of ```opencv_extra/testdata``` to get tests work correctly
3. Go to ```platforms/winrt``` and execute ```>> setup_winrt.bat "WS" "8.1" "x64"```. 
This will generate all of the files needed to build open_cv projects for selected platform in ```opencv\bin\...```. Open the ```opencv\bin\WS\8.1\x64``` directory and open the ```OpenCV.sln```.
4. Set OCV solution to Release mode and build all of the projects. They should build without errors and generate executables in “bin\WS\8.1\x64\bin\Release\”
5.	Put ```msvcr120_app.dll, msvcp120_app.dll, vccorlib120_app.dll``` libraries in that folder (possible location of these dlls is "C:\Windows\vpnplugins\juniper").  It’s important you use libraries built for the same architecture you used in step (3). Otherwise you’ll get “The application was unable to start correctly (0xc000007b)” error
6. Run opencv_test_{module}.exe via console or as usual by double clicking it. You should see output in the console window

#### Resources

* Homepage: <http://opencv.org>
* Docs: <http://docs.opencv.org>
* Q&A forum: <http://answers.opencv.org>
* Issue tracking: <http://code.opencv.org>

#### Contributing

Please read before starting work on a pull request: <http://code.opencv.org/projects/opencv/wiki/How_to_contribute>

Summary of guidelines:

* One pull request per issue;
* Choose the right base branch;
* Include tests and documentation;
* Clean up "oops" commits before submitting;
* Follow the coding style guide.
