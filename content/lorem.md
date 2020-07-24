---
menu_title: Errors
---

# Errors

Odyssey uses conventional HTTP response codes to indicate the success or failure of an API request. In general: Codes in the `2xx` range indicate success. Codes in the `4xx` range indicate an error that failed given the information provided (e.g., a required parameter was omitted or ill-formed, etc.). Codes in the `5xx` range indicate an error with our servers (these are rare).

Some `4xx` errors that require more information about what happened include an error code that briefly explains the error reported.


$$$

|   http status code summary |                                                                          |
|---------------------------:|:-------------------------------------------------------------------------|
|                   200 - OK | Everything worked as expected.                                           |
|           204 - No Content | Everything worked as expected but nothing needed to be returned.         |
|          400 - Bad Request | The request was unacceptable, often due to missing a required parameter. |
|         401 - Unauthorized | No valid token was provided.                                             |
|            403 - Forbidden | The user doesn't have permissions to perform the request.                |
|            404 - Not Found | The requested resource does not exist.                                   |
| 422 - Unprocessable Entity | The parameters were valid but the request failed.                        |
|        5XX - Server Errors | Something went wrong on our end.                                         |
