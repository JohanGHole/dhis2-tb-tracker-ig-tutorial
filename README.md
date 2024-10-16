# dhis2-tb-tracker-ig-tutorial

## Goal
In this exercise, we will showcase how to create a Logical Model representation of a DHIS2 Tracker Program. We will manually map the TB Tracker program from the Sierra Leone demo database to a FHIR IG, focusing on the machine-readable components of the IG using FSH and the IG publisher.

> **_Note_**: This exercise serves as an opinionated guide on how to represent your DHIS2 Tracker metadata as FHIR logical models and value sets. The selection of DHIS2 metadata fields to include or exclude may vary depending on your specific use case. For this tutorial, we have chosen to use the formName/displayName fields instead of name, as the latter often contains prefixes or suffixes that might not be suitable for direct mapping.

If you get stuck during the tutorial, please reference the tutorial solution found here(INSERT LINK). 

## Prerequisites
* [Visual Studio Code](https://code.visualstudio.com/download) with [vscode-language-fsh](https://marketplace.visualstudio.com/items?itemName=FHIR-Shorthand.vscode-fsh) extension installed.
* [SUSHI](https://github.com/FHIR/sushi) Installed (requires [Node.js](https://nodejs.org/en) to be installed on the user's system). Sushi is needed to compile FSH into valid FHIR definitions.
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

## Part 2 - Handling Option Sets: Creating Code System and Value Sets Using FSH
### Goal
Define FHIR code systems and value sets based on DHIS2 option sets. 

### 1 - Create FHIR Code Systems:
* For each DHIS2 option set, create a FHIR code system FSH file that lists all the available options. Use the DHIS2 metadata payload as reference.
* The general structure is as follows:
    ```fsh
    CodeSystem: Dhis2OptionSetCS
    Id: dhis2-option-set-cs
    Title: "DHIS2 Option Set Code System"
    Description: "This is the basic structure of a option set based Code System."
    * #"optionsCode1" "optionsName1"
    * #"optionsCode2" "optionsName2"
    * ...
    ```
* Example:
    ```fsh
    CodeSystem: GenderCS
    Id: gender-cs
    Title: "Gender"
    * #"Male" "Male"
    * #"Female" "Female"
    ```
### 2 - Map Code Systems to Value Sets
* We need to create corresponding FHIR Value Sets that reference the Code Systems. For each Code System defined for the tracker, create a corresponding FHIR value set.
* Example:
    ```fsh
    ValueSet: GenderVS
    Id: gender-vs
    Title: "Gender value set"
    * codes from system GenderCS
    ```
You should now have representations of all your DHIS2 option sets as FHIR code systems, with the appropriate value sets linking to them. If you are stuck or need further clarification, you can reference the tutorial solution. 

## Part 3 - Define the Logical Models for the Program Stages

## Part 4 - Define the Logical Model for the Tracker Program

## Part 5 - Review and Validate
* Run the sushi validation
## Part 6 - Add Narrative Content
* Show how to add narrative content to the IG:
  * Change `ìnput/pagecontent/index.md`