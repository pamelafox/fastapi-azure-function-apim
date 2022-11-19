[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&repo=pamelafox%2Ffastapi-azure-function-apim)

This repository includes a simple HTTP API powered by FastAPI, made for demonstration purposes only.
This API is designed to be deployed as a secured Azure Function with an API Management service in front.

![Architecture diagram for API Management Service to Function App to FastAPI](screenshot_website.png)

Thanks to the API Management policies (declared in `apimanagement.bicep`), 
making calls to the actual API requires a subscription key, but viewing the auto-generated documentation
or OpenAPI schema does not. The Azure Function has an authentication level of "function", 
so even if someone knows its endpoint, they can't make calls to it without a function key.
The API Management service does know the function key, and passes it on.

## Opening the project

This project has devcontainer support, so it will be automatically setup if you open it in Github Codespaces or in local VS Code with the Dev Containers extension. 

If you're unable to open the devcontainer, then you'll need to:

1. Create a [Python virtual environment](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments) and activate it.

2. Install requirements: 

```shell
pip3 install --user -r requirements-dev.txt
```

3. Install the [Azure Dev CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd).

## Local development

Use the local emulator from Azure Functions Core Tools to test the function locally. 
(There is no local emulator for the API Management service).

1. Open this repository in Github Codespaces or VS Code with Remote Devcontainers extension.


2. Open the Terminal and make sure you're in the root folder.
2. Run `func host start`
3. Click 'http://localhost:7071/{*route}' in the terminal, which should open the website in a new tab.
4. Change the URL to navigate to either the API at `/generate_name` or the docs at `/docs`.

## Deployment

This repo is set up for deployment using the 
[Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview),
which relies on the `azure.yaml` file and the configuration files in the `infra` folder.

1. Sign up for a [free Azure account](https://azure.microsoft.com/free/)
2. Run `azd up`. It will prompt you to login and to provide a name (like "fastfunc") and location (like "eastus"). Then it will provision the resources in your account and deploy the latest code. 
3. Once it finishes deploying, navigate to the Azure Portal URL in the output.
4. Under the _Resources_ tab, select the one labeled _API Management Service_.
5. From the _Overview_ page, copy the _Gateway URL_.
6. Append '/public/docs' to the URL and open the page in a new window.
7. To get a subscription key for API calls, open the _Subscriptions_ page in the portal and copy one of the built-in keys.

### CI/CD pipeline

This project includes a Github workflow for deploying the resources to Azure
on every push to main. That workflow requires several Azure-related authentication secrets to be stored as Github action secrets. To set that up, run:

```shell
azd pipeline config
```

### Monitoring

The deployed resources include a Log Analytics workspace with an Application Insights dashboard to measure metrics like server response time.

To open that dashboard, run this command once you've deployed:

```shell
azd monitor --overview
```

## Getting help

If you're working with this project and running into issues, please post in [Discussions](/discussions).