[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&repo=pamelafox%2Ffastapi-azure-function-apim)

This repository includes a simple HTTP API powered by FastAPI, made for demonstration purposes only.
This API is designed to be deployed as a secured Azure Function with an API Management service in front.
Thanks to the API Management policies (declared in `apimanagement.bicep`), 
making calls to the actual API requires a subscription key, but viewing the auto-generated documentation
or OpenAPI schema does not. The Azure Function has an authentication level of "function", 
so even if someone knows its endpoint, they can't make calls to it without a function key.
The API Management service does know the function key, and passes it on.

## Local development

Use the local emulator from Azure Functions Core Tools to test the function locally.

1. Open this repository in Github Codespaces or VS Code with Remote Devcontainers extension.
2. Open the Terminal and make sure you're in the root folder.
2. Run `func host start`
3. Click 'http://localhost:7071/{*route}' in the terminal, which should open the website in a new tab.
4. Change the URL to navigate to either the API at `/generate_name` or the docs at `/docs`.

## Deployment

1. Run `azd up`.

2. Navigate to the Azure Portal URL in the output.

3. Under the _Resources_ tab, select the one labeled _API Management Service_.

4. From the _Overview_ page, copy the _Gateway URL_.

5. Append `/public/docs' to the URL and open the page in a new window.

6. To get a subscription key for API calls, open the _Subscriptions_ page in the portal and copy one of the built-in keys.
