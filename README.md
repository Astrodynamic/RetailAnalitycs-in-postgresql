# RetailAnalitycs in postgresql

This repository contains scripts and functions for creating a database, creating views, managing user roles, and forming personal offers aimed at the growth of the average check, increasing the frequency of visits, and cross-selling.

## Table of Contents

- [RetailAnalitycs in postgresql](#retailanalitycs-in-postgresql)
  - [Table of Contents](#table-of-contents)
  - [Database Creation](#database-creation)
  - [Views Creation](#views-creation)
  - [User Roles](#user-roles)
  - [Forming Personal Offers for Average Check Growth](#forming-personal-offers-for-average-check-growth)
  - [Forming Personal Offers for Increasing Frequency of Visits](#forming-personal-offers-for-increasing-frequency-of-visits)
  - [Forming Personal Offers for Cross-Selling](#forming-personal-offers-for-cross-selling)
  - [Input Data](#input-data)
    - [Personal information Table](#personal-information-table)
    - [Cards Table](#cards-table)
    - [Transactions Table](#transactions-table)
    - [Checks Table](#checks-table)
    - [Product grid Table](#product-grid-table)
    - [Stores Table](#stores-table)
    - [SKU group Table](#sku-group-table)
    - [Date of analysis formation Table](#date-of-analysis-formation-table)
  - [Output data](#output-data)
    - [Customers View](#customers-view)
    - [Purchase history View](#purchase-history-view)
    - [Periods View](#periods-view)
    - [Groups View](#groups-view)
  - [License](#license)

## Database Creation

To create the database and tables described in the Input data, follow the steps below:

1. Execute the `part1.sql` script provided in the repository.
2. This script will create the necessary tables and also include procedures for importing and exporting data for each table from/to CSV and TSV files.
3. Make sure to upload the required CSV and TSV files from the datasets folder to the repository.

## Views Creation

To create the views described in the Output data, follow the steps below:

1. Execute the `part2.sql` script provided in the repository.
2. This script will create the views and include test queries for each view.

## User Roles

To set up user roles and their permissions, follow the steps below:

1. Execute the `part3.sql` script provided in the repository.
2. This script will create the roles and assign the following permissions:
   - Administrator: This role has full permissions to edit and view any information, as well as start and stop the processing.
   - Visitor: This role only has permission to view information of all tables.

## Forming Personal Offers for Average Check Growth

To form personal offers aimed at the growth of the average check, follow the steps below:

1. Execute the `part4.sql` script provided in the repository.
2. This script contains a function that determines offers based on the average check calculation method, first and last dates of the period, number of transactions, coefficient of average check increase, maximum churn index, maximum share of transactions with a discount, and allowable share of margin.
3. The function will output the customer ID, average check target value, offer group, and maximum discount depth for each offer.

## Forming Personal Offers for Increasing Frequency of Visits

To form personal offers aimed at increasing the frequency of visits, follow the steps below:

1. Execute the `part5.sql` script provided in the repository.
2. This script contains a function that determines offers based on the first and last dates of the period, added number of transactions, maximum churn index, maximum share of transactions with a discount, and allowable margin share.
3. The function will output the customer ID, period start date, period end date, target number of transactions, offer group, and maximum discount depth for each offer.

## Forming Personal Offers for Cross-Selling

To form personal offers aimed at cross-selling, follow the steps below:

1. Execute the `part6.sql` script provided in the repository.
2. This script contains a function that determines offers based on the number of groups, maximum churn index, maximum consumption stability index, maximum SKU share, and allowable margin share.
3. The function will output the customer ID, SKU offers, and maximum discount depth for each offer.

---

## Input Data

### Personal information Table

|       **Field**       | **System field name**  |                                   **Format / possible values**                                    | **Description** |
| :-------------------: | :--------------------: | :-----------------------------------------------------------------------------------------------: | :-------------: |
|      Customer ID      |      Customer_ID       |                                                ---                                                |       ---       |
|         Name          |     Customer_Name      | Cyrillic, the first letter is capitalized, the rest are upper case, dashes and spaces are allowed |       ---       |
|        Surname        |    Customer_Surname    | Cyrillic, the first letter is capitalized, the rest are upper case, dashes and spaces are allowed |       ---       |
|    Customer E-mail    | Customer_Primary_Email |                                           E-mail format                                           |       ---       |
| Customer phone number | Customer_Primary_Phone |                                     +7 and 10 Arabic numerals                                     |       ---       |

---

### Cards Table

|  **Field**  | **System field name** | **Format / possible values** |          **Description**           |
| :---------: | :-------------------: | :--------------------------: | :--------------------------------: |
|   Card ID   |   Customer_Card_ID    |             ---              |                ---                 |
| Customer ID |      Customer_ID      |             ---              | One customer can own several cards |

---

### Transactions Table

|    **Field**     | **System field name** | **Format / possible values** |                          **Description**                           |
| :--------------: | :-------------------: | :--------------------------: | :----------------------------------------------------------------: |
|  Transaction ID  |    Transaction_ID     |             ---              |                            Unique value                            |
|     Card ID      |   Customer_Card_ID    |             ---              |                                ---                                 |
| Transaction sum  |   Transaction_Summ    |        Arabic numeral        | Transaction sum in rubles(full purchase price excluding discounts) |
| Transaction date | Transaction_DateTime  |     dd.mm.yyyy hh:mm:ss      |            Date and time when the transaction was made             |
|      Store       | Transaction_Store_ID  |           Store ID           |              The store where the transaction was made              |

---

### Checks Table

|                    **Field**                     | **System field name** | **Format / possible values** |                                                **Description**                                                |
| :----------------------------------------------: | :-------------------: | :--------------------------: | :-----------------------------------------------------------------------------------------------------------: |
|                  Transaction ID                  |    Transaction_ID     |             ---              |                           Transaction ID is specified for all products in the check                           |
|               Product in the check               |        SKU_ID         |             ---              |                                                      ---                                                      |
|          Number of pieces or kilograms           |      SKU_Amount       |        Arabic numeral        |                                     The quantity of the purchased product                                     |
| Total amount for which the product was purchased |       SKU_Summ        |        Arabic numeral        | The purchase amount of the actual volume of this product in rubles (full price without discounts and bonuses) |
|          The paid price of the product           |     SKU_Summ_Paid     |        Arabic numeral        |                      The amount actually paid for the product not including the discount                      |
|                 Discount granted                 |     SKU_Discount      |        Arabic numeral        |                          The size of the discount granted for the product in rubles                           |

---

### Product grid Table

|       **Field**        | **System field name** |         **Format / possible values**          |                                                                                                        **Description**                                                                                                        |
| :--------------------: | :-------------------: | :-------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|       Product ID       |        SKU_ID         |                      ---                      |                                                                                                              ---                                                                                                              |
|      Product name      |       SKU_Name        | Cyrillic, Arabic numerals, special characters |                                                                                                              ---                                                                                                              |
|       SKU group        |       Group_ID        |                      ---                      | The ID of the group of related products to which the product belongs (for example, same type of yogurt of the same manufacturer and volume, but different flavors). One identifier is specified for all products in the group |
| Product purchase price |  SKU_Purchase_Price   |                Arabic numeral                 |                                                                                       The purchase price of the product for this store                                                                                        |
|  Product retail price  |   SKU_Retail_Price    |                Arabic numeral                 |                                                                               The sale price of the product excluding discounts for this store                                                                                |

---

### Stores Table

|       **Field**        | **System field name** | **Format / possible values** |                         **Description**                          |
| :--------------------: | :-------------------: | :--------------------------: | :--------------------------------------------------------------: |
|         Store          | Transaction_Store_ID  |             ---              |                               ---                                |
|       Product ID       |        SKU_ID         |             ---              |                               ---                                |
| Product purchase price |  SKU_Purchase_Price   |        Arabic numeral        |           Purchasing price of products for this store            |
|  Product retail price  |   SKU_Retail_Price    |        Arabic numeral        | The sale price of the product excluding discounts for this store |

---

### SKU group Table

| **Field**  | **System field name** |         **Format / possible values**          | **Description** |
| :--------: | :-------------------: | :-------------------------------------------: | :-------------: |
| SKU group  |       Group_ID        |                      ---                      |       ---       |
| Group name |      Group_Name       | Cyrillic, Arabic numerals, special characters |       ---       |

---

### Date of analysis formation Table

|    **Field**     | **System field name** | **Format / possible values** | **Description** |
| :--------------: | :-------------------: | :--------------------------: | :-------------: |
| Date of analysis |  Analysis_Formation   |     dd.mm.yyyy hh:mm:ss      |       ---       |

---

## Output data

### Customers View

|                   **Field**                   |     **System field name**      | **Format / possible values** |                                   **Description**                                    |
| :-------------------------------------------: | :----------------------------: | :--------------------------: | :----------------------------------------------------------------------------------: |
|                  Customer ID                  |          Customer_ID           |             ---              |                                     Unique value                                     |
|          Value of the average check           |     Customer_Average_Check     |   Arabic numeral, decimal    |             Value of the average check in rubles for the analyzed period             |
|             Average check segment             | Customer_Average_Check_Segment |      High; Middle; Low       |                                 Segment description                                  |
|          Transaction frequency value          |       Customer_Frequency       |   Arabic numeral, decimal    | Value of customer visit frequency in the average number of days between transactions |
|         Transaction frequency segment         |   Customer_Frequency_Segment   | Often; Occasionally; Rarely  |                                 Segment description                                  |
| Number of days since the previous transaction |    Customer_Inactive_Period    |   Arabic numeral, decimal    |              Number of days passed since the previous transaction date               |
|                  Churn rate                   |      Customer_Churn_Rate       |   Arabic numeral, decimal    |                           Value of the customer churn rate                           |
|              Churn rate segment               |     Customer_Churn_Segment     |      High; Middle; Low       |                                 Segment description                                  |
|                Segment number                 |        Customer_Segment        |        Arabic numeral        |               The number of the segment to which the customer belongs                |
|                 Main store ID                 |     Customer_Primary_Store     |             ---              |                                         ---                                          |

---

### Purchase history View

|     **Field**     | **System field name** | **Format / possible values** |                                                                                                        **Description**                                                                                                        |
| :---------------: | :-------------------: | :--------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|    Customer ID    |      Customer_ID      |             ---              |                                                                                                              ---                                                                                                              |
|  Transaction ID   |    Transaction_ID     |             ---              |                                                                                                              ---                                                                                                              |
| Transaction date  | Transaction_DateTime  | dd.mm.yyyyy hh:mm:ss.0000000 |                                                                                            The date when the transaction was made                                                                                             |
|     SKU group     |       Group_ID        |             ---              | The ID of the group of related products to which the product belongs (for example, same type of yogurt of the same manufacturer and volume, but different flavors). One identifier is specified for all products in the group |
|    Prime cost     |      Group_Cost       |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |
| Base retail price |      Group_Summ       |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |
| Actual cost paid  |    Group_Summ_Paid    |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |

---

### Periods View

|               **Field**               |   **System field name**   | **Format / possible values** |                                                                                                        **Description**                                                                                                        |
| :-----------------------------------: | :-----------------------: | :--------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|              Customer ID              |        Customer_ID        |             ---              |                                                                                                              ---                                                                                                              |
|               SKU group               |         Group_ID          |             ---              | The ID of the group of related products to which the product belongs (for example, same type of yogurt of the same manufacturer and volume, but different flavors). One identifier is specified for all products in the group |
|  Date of first purchase of the group  | First_Group_Purchase_Date | yyyy-mm-dd hh:mm:ss.0000000  |                                                                                                              ---                                                                                                              |
|  Date of last purchase of the group   | Last_Group_Purchase_Date  | yyyy-mm-dd hh:mm:ss.0000000  |                                                                                                              ---                                                                                                              |
| Number of transactions with the group |      Group_Purchase       |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |
|     Intensity of group purchases      |      Group_Frequency      |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |
|        Minimum group discount         |    Group_Min_Discount     |   Arabic numeral, decimal    |                                                                                                              ---                                                                                                              |

---

### Groups View

|               **Field**               | **System field name**  | **Format / possible values** |                                                              **Description**                                                               |
| :-----------------------------------: | :--------------------: | :--------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------: |
|              Customer ID              |      Customer_ID       |             ---              |                                                                    ---                                                                     |
|               Group ID                |        Group_ID        |             ---              |                                                                    ---                                                                     |
|            Affinity index             |  Group_Affinity_Index  |   Arabic numeral, decimal    |                                                   Customer affinity index for this group                                                   |
|              Churn index              |    Group_Churn_Rate    |   Arabic numeral, decimal    |                                                 Customer churn index for a specific group                                                  |
|            Stability index            | Group_Stability_Index  |   Arabic numeral, decimal    |                               Indicator demonstrating the stability of the customer consumption of the group                               |
|      Actual margin for the group      |      Group_Margin      |   Arabic numeral, decimal    |                                   Indicator of the actual margin for the group for a particular customer                                   |
| Share of transactions with a discount |  Group_Discount_Share  |   Arabic numeral, decimal    | Share of purchasing transactions of the group by a customer, within which the discount was applied (excluding the loyalty program bonuses) |
|     Minimum size of the discount      | Group_Minimum_Discount |   Arabic numeral, decimal    |                                            Minimum size of the group discount for the customer                                             |
|           Average discount            | Group_Average_Discount |   Arabic numeral, decimal    |                                            Average size of the group discount for the customer                                             |

---

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use and modify the code according to your needs.
