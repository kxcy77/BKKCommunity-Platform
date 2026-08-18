# Developing the BKK Community web app in Visual Studio Code

## What this means

The BKK Community website is a PHP/MySQL web application. PHP is run by a web server; it is not compiled into an executable. On macOS, the supported Microsoft development environment is **Visual Studio Code**, not the retired Visual Studio for Mac product.

## Open and run the project

1. Open Visual Studio Code.
2. Select **File > Open Folder** and choose this `BKKCommunity-Web-live` folder.
3. If prompted, install the recommended PHP extensions.
4. Press **Command + Shift + B** and choose **BKK: Run web app locally**.
5. Open [http://127.0.0.1:8080](http://127.0.0.1:8080) in a browser.
6. Stop the server with **Control + C** in the Visual Studio Code terminal when finished.

The site can be viewed without a database in clearly labelled demonstration mode. Persistent members, events, discounts, attendance and password reset require the configured MySQL and email environment variables described in the main README.

## Check the code before a hand-in

Press **Command + Shift + B** and choose **BKK: Check PHP syntax**. This checks the PHP files for syntax errors using the same PHP installation configured for this workspace.

## Documentation wording for the group report

Use this accurate statement:

> The BKK Community web application was developed and tested in Visual Studio Code using PHP 8.3+ and MySQL 8. The application runs locally through PHP's built-in development server and is deployed as a PHP web service.

Do not state that it was “compiled in Visual Studio.” That would be technically false for this PHP project.
