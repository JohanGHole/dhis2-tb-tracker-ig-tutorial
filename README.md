# dhis2-tb-tracker-ig-tutorial

## Goal
The goal of this tutorial is to showcase how to create a Logical Model representation of a DHIS2 Tracker Program. For this exercise, we will manually map the TB Tracker program from the Sierra Leone demo database to a FHIR IG, focusing on the machine-readable components of the IG using FSH and the IG publisher. 

## Prerequisites
* [Visual Studio Code](https://code.visualstudio.com/download) with FSH extension installed.
* [SUSHI](https://github.com/FHIR/sushi) Installed (requires [Node.js](https://nodejs.org/en) to be installed on the user's system).
* Access to a local instance of DHIS2 with the Sierra Leone database installed. Alternatively, you can use the online play server found [here](https://play.im.dhis2.org/dev/dhis-web-login/).

## Part 1 - Fetch the TB tracker program's metadata
The goal of part 1 is to get familiar with the TB tracker program's metadata and how it is structured.

### 1 - Fetch the DHIS2 metadata
Before using the API, it might be a good idea to start by using the DHIS2 UI to explore the tracker metadata. Navigate to the [DHIS2 Maintenance App](https://play.im.dhis2.org/dev/dhis-web-maintenance/index.html#/edit/programSection/program/ur1Edk5Oe2n) and [DHIS2 Capture App](https://play.im.dhis2.org/dev/dhis-web-maintenance/index.html#/edit/programSection/program/ur1Edk5Oe2n) to get an overview of how the TB tracker metadata is structured.

Now, use the [DHIS2 API](https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-240/metadata.html) to fetch the metadata of the TB tracker program:

```http
GET /api/programs/ur1Edk5Oe2n
```
Example API query to fetch all of the TB program's metadata:

```http
GET /api/programs/ur1Edk5Oe2n?fields=*
```
However, this query will not include the nested structures such as program stages and tracked entity attributes directly. By default, the `fields=*` only retrieves the top-level fields of the program, and nested structures like `programStages` will only return an array of `id` references (e.g., `[{id: "stage1"}, {id: "stage2"}]`).

We therefore need to refine the queries to only pull the necessary details. For the scope of this exercise, we will need the following fields: 
```http
GET api/programs/ur1Edk5Oe2n?fields=name,displayName,description,,programStages[name,description,programStageDataElements[compulsory,dataElement[formName,displayName,valueType,description,optionSet[options[code,name]]]]],programTrackedEntityAttributes[displayName,trackedEntityAttribute[displayName,valueType,description,,optionSet[options[code,name]]]]
```
This fetches:
* **Top-level Program Fields:**
  * `name`: The internal name of the program (required field in DHIS2).
  * `displayName`: The display name of the program. 
  * `description`: A brief description of the program. 
* **Program Stages:**
  * `name`: The internal name of the program stage (required field in DHIS2)
  * `description`: A brief description of the program stage.
  * **Program Stage Data Elements:**
    * `compulsory`: Whether the data element is mandatory in this stage. 
    * **Data Element Fields:**
      * `formName`: The name of the data element as used in forms.
      * `displayName`: The display name of the data element. 
      * `valueType`: The data value type (e.g., `TEXT`, `BOOLEAN`)
      * `description`: A brief description of the data element.
      * Option Set (if the data element is an option set):
        * `options`: The possible options associated wit the data element's option set. 
          * `code`: The option code.
          * `name`: The display name of the option. 
* **Program Tracked Entity Attributes:**
  * displayName: The display name of the tracked entity attribute. 
  * **Tracked Entity Attribute:**
    * displayName: The displayname of the tracked entity attribute. 
    * valueType: the data type of the attribute (e.g., `TEXT`,`BOOLEAN`).
    * description: A brief description of the attribute. 
    * Option Set (if the TEA is an option set):
      * options: The options associated with the TEA's option set. 
        * code: the option code.
        * name: The name of the option.

You should now have a payload like this:
```json
{
  "name": "TB program",
  "displayName": "TB program",
  "programStages": [
    {
      "name": "Lab monitoring",
      "description": "Laboratory monitoring",
      "programStageDataElements": [
        {
          "dataElement": {
            "formName": "CD4",
            "valueType": "TRUE_ONLY",
            "displayName": "TB lab CD4"
          },
          "compulsory": false
        },
        ...
      ]
    },
    ...
  ],
  "programTrackedEntityAttributes": [
    {
      "displayName": "TB program First name",
      "trackedEntityAttribute": {
        "description": "First name",
        "valueType": "TEXT",
        "displayName": "First name"
      }
    },
    ...
  ]
}
```
The complete payload is available in the repository within the `input/examples` folder.
Please note that for your use-case, you might need to add extra fields, such as `enrollmentDateLabel`, `id`and so on. If you would rather use the  attribute / data element `name` definition rather than the `formName` / `displayName`, this is also possible.

## 2 - Authoring the IG using FSH
### Goal
Create the FHIR Logical Model definitions for the DHIS2 tracker program 