# Finance Tracker

---

## Project Team Members

| Name | Matric Number |
|------|---------------|
| Muhammad Ikmal Hakimi Bin Rosli | 2210827 |
| Muhammad Muslihuddin Bin Mustaffar | 2213263 |
| Johan Adam Bin Ahmad | 2116387 |

---

## Introduction
This is a mobile application designed to help individuals manage their personal finances effectively. Finance Tracker enables users to set monthly budgets, scan and track receipts digitally, categorize expenses by payment type, and maintain comprehensive financial records—all in one convenient platform.

### Problem Description
Many individuals struggle with managing their personal finances due to a lack of proper tracking tools. Without a systematic approach to monitoring expenses, people often:

- Overspend and exceed their monthly budgets
- Lose track of where their money goes
- Misplace physical receipts, making it difficult to review past transactions
- Find it challenging to identify spending patterns across different payment methods

Traditional methods of tracking expenses using spreadsheets or physical records are time-consuming and inefficient. Physical receipts can easily be lost, damaged, or fade over time, making it nearly impossible to maintain accurate financial records.

### Motivation
The current process of managing personal finances presents several specific challenges:

- **Budget Overruns**: Without real-time tracking and monthly budget limits, individuals often overspend without realizing it until it's too late.

- **Receipt Management**: Physical receipts pile up and become disorganized, making it difficult to track expenses or verify past purchases.

- **Payment Type Confusion**: With multiple payment methods (cash, e-wallets, cards) in use, it's hard to get a clear picture of spending patterns across different channels.

- **Lack of Financial Awareness**: Without proper tracking tools, individuals struggle to identify spending habits and make informed financial decisions.

### Relevance
This project addresses real-world financial management challenges by providing a comprehensive solution for budget tracking, receipt digitization, and expense categorization. By combining budget monitoring with digital receipt management and payment type tracking, Finance Tracker empowers users to take control of their finances and make better spending decisions.

---

## Objectives of the Proposed Mobile App

The primary objective of this project is to develop a mobile application that helps individuals manage their personal finances effectively by tracking expenses, setting budgets, and digitizing receipts. The specific objectives are:

1. **Monthly Budget Management**: Enable users to set monthly budgets and track their spending in real-time to prevent overspending and maintain financial discipline.

2. **Digital Receipt Storage**: Allow users to scan and store receipts digitally, reducing reliance on physical receipts and preventing loss or damage of important transaction records.

3. **Receipt Scanning and Data Extraction**: Utilize Optical Character Recognition (OCR) technology to extract relevant information from scanned receipts, including merchant name, date, amount, and items purchased.

4. **Payment Type Categorization**: Track expenses by payment method (cash payment, e-wallet, card payment) to provide users with insights into their spending patterns across different payment channels.

5. **Profile Management**: Provide users with customizable profile settings to personalize their financial tracking experience and manage account preferences.

6. **User-Friendly Interface**: Design an intuitive and accessible user interface that simplifies the process of budget tracking, receipt scanning, and expense management.

---

## Target Users

The primary target users for this application are **individuals seeking better financial management**, including:

| User Group | Description |
|------------|-------------|
| **Young Professionals** | Individuals aged 18-35 who are starting their careers and want to develop good financial habits |
| **Students** | College and university students managing limited budgets and looking to track their spending |
| **Families** | Households aiming to manage shared expenses and stay within monthly budgets |
| **Budget-Conscious Individuals** | Anyone who wants to gain better control over their finances and understand their spending patterns |
| **Small Business Owners** | Entrepreneurs and freelancers who need to track business expenses across different payment methods |

---

## Features and Functionalities

### Core Modules

#### 1. User Authentication
- Secure account creation and login processes
- Data privacy protection
- Personalized user experiences

#### 2. Monthly Budget Management
- Set monthly spending limits
- Real-time budget tracking
- Visual progress indicators showing remaining budget
- Budget vs. actual spending comparison
- Budget alerts when approaching limits

#### 3. Receipt Digitization and Scanning
- Camera integration for scanning physical receipts
- **OCR Technology**: Extract information from scanned receipts (merchant name, date, amount, items)
- Automatic data extraction for quick entry
- Image quality optimization
- Manual entry option for backup

#### 4. Payment Type Categorization
- Track expenses by payment method:
  - **Cash Payment**: Record cash transactions
  - **E-Wallet**: Track e-wallet payments (e.g., Touch 'n Go, GrabPay, Boost)
  - **Card Payment**: Monitor credit and debit card transactions
- Payment method analytics and insights
- Visual breakdown of spending by payment type

#### 5. Cloud-Based Storage
- Secure storage of digitized receipts
- Data integrity and accessibility
- Backup and synchronization across devices

#### 6. Financial Tracking
- Add receipts to track spending against budget
- Categorize expenses (Food, Transportation, Shopping, Entertainment, etc.)
- Filter and search receipts by date, amount, or payment type
- View spending history and trends
- Monthly and yearly expense reports

#### 7. Profile Settings
- Customize user profile information
- Manage account preferences
- Set notification preferences
- Currency and language settings
- Data privacy controls

#### 8. Export Functionality
- Export financial reports as PDF or Excel files
- Generate monthly spending summaries
- Share reports via email or messaging apps
- Backup and restore functionality

#### 9. User Notifications
- Budget limit alerts
- Monthly spending summaries
- Reminders to scan receipts
- System updates and maintenance notifications

### UI Components

- **Dashboard**: Overview of monthly budget status, spending by payment type, and recent transactions
- **Budget Screen**: Set and monitor monthly budgets with visual progress indicators
- **Camera Interface**: Intuitive scanning interface for capturing receipts
- **Add Receipt Screen**: Manual entry or OCR-extracted data with payment type selection
- **Receipt List**: Organized view with filtering by payment type, date, and amount
- **Receipt Detail View**: Full receipt information with image preview and payment method
- **Analytics Screen**: Visual charts and graphs showing spending patterns by category and payment type
- **Profile/Settings**: User preferences, account management, notification settings, and help center

---

## Proposed UI Mock-up

Below are the key screen designs that illustrate the user interface of the application:

### Set Budget Screen
The set budget interface allows users to define their monthly spending limits and track their financial goals.

![Set Budget Screen](C:\Users\Adamj\Finance Tracker\set budget.jpeg)

### Add Receipt Screen
The add receipt interface enables users to scan or manually enter receipt information, categorize expenses, and select payment types.

![Add Receipt Screen](C:\Users\Adamj\Finance Tracker\add receipt.jpeg)

---

## Architecture / Technical Design

### Development Framework
The application will be developed as a **cross-platform mobile app** to ensure broad accessibility and user convenience.

### Widget/Component Structure

The application is organized into modular components that work together to provide a seamless user experience.

**Authentication Module**: Handles user registration, login, and password recovery to ensure secure access to the application.
- a. Login Screen
- b. Registration Screen
- c. Password Reset Screen

**Dashboard Screen**: Provides users with an overview of their financial status and quick access to key functions.
- a. Budget Overview Widget
- b. Spending by Payment Type Widget
- c. Recent Transactions Widget
- d. Quick Action Buttons (Scan Receipt, Add Expense)

**Budget Management Module**: Enables users to set and monitor monthly budgets.
- a. Budget Setting Component
- b. Budget Progress Indicator
- c. Budget Alert Component

**Receipt Scanner Module**: Enables users to capture and process physical receipts using their device camera.
- a. Camera Component
- b. Image Preview Component
- c. OCR Processing Component

**Add Receipt Module**: Allows users to add receipts manually or from scanned data.
- a. Receipt Form Component
- b. Payment Type Selector (Cash, E-Wallet, Card)
- c. Category Selector
- d. OCR Data Preview

**Receipt Management Module**: Allows users to view, organize, and manage their digitized receipts.
- a. Receipt List Component
- b. Filter/Sort Component (by date, payment type, amount)
- c. Receipt Detail Screen
- d. Edit Receipt Component

**Analytics Module**: Visualizes spending patterns and financial insights.
- a. Spending Charts (by category, payment type, time period)
- b. Budget vs. Actual Comparison
- c. Monthly Trends

**Export Module**: Facilitates the compilation and export of financial reports.
- a. Date Range Selector
- b. Report Type Selector
- c. Export Format Selector (PDF, Excel)

**Profile/Settings Module**: Manages user account information, preferences, and application settings.
- a. User Profile Component
- b. Notification Settings
- c. Currency/Language Settings
- d. Help/Support Component

**Common Components**: Reusable UI elements used throughout the application for consistency.
- a. Loading Indicators
- b. Error Boundaries
- c. Alert/Dialog Components
- d. Custom Buttons/Inputs

### State Management Approach

1. **Global State**:
   - User authentication status
   - User profile information
   - App settings and preferences
   - Network connectivity status
   - Current monthly budget

2. **Feature-Specific State**:
   - Receipt list data
   - Budget tracking data
   - Payment type statistics
   - Category information
   - Filter and sort preferences
   - Export selections
   - Analytics data

3. **Local Component State**:
   - Form inputs
   - UI interactions (modals, dropdowns)
   - Loading states for individual operations
   - Camera/scanner state

---

## Data Model

### Entity Relationship Diagram (ERD) 

**Entities:**

1. **User**
   - Primary Key: userId
   - Attributes: email, displayName, createdAt, lastLogin, preferences, currency, language

2. **Budget**
   - Primary Key: budgetId
   - Foreign Key: userId
   - Attributes: month, year, budgetLimit, currentSpending, createdAt, updatedAt

3. **Receipt**
   - Primary Key: receiptId
   - Foreign Key: userId, budgetId
   - Attributes: imageUrl, merchantName, amount, date, category, paymentType, items, extractedData, notes

4. **PaymentType**
   - Primary Key: paymentTypeId
   - Attributes: name (Cash, E-Wallet, Card), icon, description

5. **Category**
   - Primary Key: categoryId
   - Attributes: name, description, icon, keywords

6. **Export**
   - Primary Key: exportId
   - Foreign Key: userId
   - Attributes: month, year, format, receiptCount, totalAmount, downloadUrl, createdAt

**Relationships:**

- **User ↔ Budget**: One-to-Many (One user can have many monthly budgets)
- **User ↔ Receipt**: One-to-Many (One user can have many receipts)
- **Budget ↔ Receipt**: One-to-Many (One budget period contains many receipts)
- **PaymentType ↔ Receipt**: One-to-Many (One payment type can be used for many receipts)
- **Category ↔ Receipt**: One-to-Many (One category can be assigned to many receipts)
- **User ↔ Export**: One-to-Many (One user can create many exports)

### Data Access Patterns

1. **Retrieve all receipts for a user**: Query `users/{userId}/receipts`
2. **Filter receipts by payment type**: Query with `where('paymentType', '==', paymentTypeId)`
3. **Filter receipts by category**: Query with `where('category', '==', categoryId)`
4. **Filter receipts by date range**: Query with `where('date', '>=', startDate).where('date', '<=', endDate)`
5. **Get current month budget**: Query with `where('month', '==', currentMonth).where('year', '==', currentYear)`
6. **Calculate spending by payment type**: Aggregate receipts grouped by `paymentType`
7. **Recent receipts**: Query with `orderBy('createdAt', 'desc').limit(10)`

---

## Flowchart

The following flowchart illustrates the user interaction and navigation flow throughout the application:

![Finance Tracker Application Flowchart](images/flowchart_financetracker.drawio.png)

The flowchart demonstrates the complete user journey from authentication through budget setting, receipt scanning, expense tracking by payment type, financial analytics, and export processes, showing how users interact with various modules and the decision points throughout the application flow.

---

## References

1. Personal Finance Management Best Practices. (n.d.). Retrieved January 16, 2026, from various financial literacy resources.

2. Flutter Documentation. (n.d.). Get started: Learn Flutter. https://docs.flutter.dev/get-started/learn-flutter

3. OCR Technology in Mobile Applications. (n.d.). Implementation guides for receipt scanning and data extraction.

4. Mobile Payment Systems in Malaysia. (n.d.). Overview of e-wallet and digital payment platforms.

---
