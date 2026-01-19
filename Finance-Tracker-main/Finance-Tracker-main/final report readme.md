# Finance Tracker - Final Report

## Project Team

| Name | Matric Number |
|------|---------------|
| Muhammad Ikmal Hakimi Bin Rosli | 2210827 |
| Muhammad Muslihuddin Bin Mustaffar | 2213263 |
| Johan Adam Bin Ahmad | 2116387 |

---

## Final UI Screenshots

_Screenshots to be added here_

---

## Summary of Achieved Features

### Core Functionalities Implemented

#### ✅ User Authentication
- Secure account creation and login processes
- Data privacy protection for all user information
- Personalized user experiences based on individual profiles

#### ✅ Monthly Budget Management
- Ability to set monthly spending limits
- Real-time budget tracking with automatic updates
- Visual progress indicators showing remaining budget
- Budget vs. actual spending comparison analytics
- Budget alerts when approaching spending limits

#### ✅ Receipt Digitization and Scanning
- Camera integration for scanning physical receipts
- **OCR Technology**: Automated extraction of merchant name, date, amount, and items from scanned receipts
- Automatic data population for quick entry
- Image quality optimization for better scanning results
- Manual entry option as backup method

#### ✅ Payment Type Categorization
Successfully implemented expense tracking by payment method:
- **Cash Payment**: Record and track cash transactions
- **E-Wallet**: Monitor e-wallet payments (Touch 'n Go, GrabPay, Boost, etc.)
- **Card Payment**: Track credit and debit card transactions
- Payment method analytics with visual breakdowns
- Spending insights by payment type

#### ✅ Cloud-Based Storage
- Secure storage of all digitized receipts
- Data integrity and accessibility across sessions
- Backup and synchronization capabilities

#### ✅ Financial Tracking System
- Add and categorize receipts to track spending against budget
- Multiple expense categories (Food, Transportation, Shopping, Entertainment, etc.)
- Filter and search receipts by date, amount, or payment type
- Comprehensive spending history and trend analysis
- Monthly and yearly expense reports

#### ✅ Profile Settings
- Customizable user profile information
- Account preferences management
- Notification preferences configuration
- Currency and language settings
- Data privacy controls

#### ✅ Export Functionality
- Export financial reports as PDF or Excel files
- Generate detailed monthly spending summaries
- Share reports via email or messaging apps
- Backup and restore functionality

#### ✅ User Notifications
- Budget limit alerts when approaching thresholds
- Monthly spending summaries
- Reminders to scan and log receipts
- System updates and maintenance notifications

---

## Technical Explanation

### Application Architecture

The Finance Tracker application is built as a **cross-platform mobile application** designed for broad accessibility and optimal user experience.

#### Development Framework
- Cross-platform mobile development framework for iOS and Android compatibility
- Modular component architecture for maintainability and scalability
- State management system for efficient data flow

#### Widget/Component Structure

The application follows a modular architecture with the following key components:

**1. Authentication Module**
- Login Screen
- Registration Screen
- Password Reset Screen
- Secure authentication handling

**2. Dashboard Screen**
- Budget Overview Widget displaying current budget status
- Spending by Payment Type Widget with visual breakdowns
- Recent Transactions Widget for quick access
- Quick Action Buttons (Scan Receipt, Add Expense)

**3. Budget Management Module**
- Budget Setting Component for monthly limit configuration
- Budget Progress Indicator with real-time updates
- Budget Alert Component for threshold notifications

**4. Receipt Scanner Module**
- Camera Component for receipt capture
- Image Preview Component for verification
- OCR Processing Component for data extraction

**5. Add Receipt Module**
- Receipt Form Component for data entry
- Payment Type Selector (Cash, E-Wallet, Card)
- Category Selector for expense classification
- OCR Data Preview for automated entries

**6. Receipt Management Module**
- Receipt List Component with organized view
- Filter/Sort Component (by date, payment type, amount)
- Receipt Detail Screen for full information display
- Edit Receipt Component for modifications

**7. Analytics Module**
- Spending Charts (by category, payment type, time period)
- Budget vs. Actual Comparison visualizations
- Monthly Trends analysis

**8. Export Module**
- Date Range Selector for report generation
- Report Type Selector for customization
- Export Format Selector (PDF, Excel)

**9. Profile/Settings Module**
- User Profile Component
- Notification Settings
- Currency/Language Settings
- Help/Support Component

**10. Common Components**
- Loading Indicators for asynchronous operations
- Error Boundaries for graceful error handling
- Alert/Dialog Components for user interactions
- Custom Buttons/Inputs for consistent UI

#### State Management

**Global State:**
- User authentication status
- User profile information
- App settings and preferences
- Network connectivity status
- Current monthly budget data

**Feature-Specific State:**
- Receipt list data
- Budget tracking data
- Payment type statistics
- Category information
- Filter and sort preferences
- Export selections
- Analytics data

**Local Component State:**
- Form inputs and validation
- UI interactions (modals, dropdowns)
- Loading states for individual operations
- Camera/scanner state

#### Technical Features

**OCR Implementation:**
- Integration of Optical Character Recognition technology for receipt data extraction
- Automated parsing of merchant name, date, amount, and itemized purchases
- Fallback to manual entry when OCR accuracy is insufficient

**Cloud Storage:**
- Secure cloud-based storage for all receipt images
- Data synchronization across devices
- Backup and restore capabilities

**Payment Type Tracking:**
- Comprehensive tracking across three payment methods (Cash, E-Wallet, Card)

---

## Limitations and Future Enhancements

### Current Limitations

#### 1. OCR Accuracy
- **Limitation**: OCR technology may struggle with poor quality images, handwritten receipts, or faded receipts
- **Impact**: May require manual data entry or verification in some cases

#### 2. Offline Functionality
- **Limitation**: Limited functionality when device is offline
- **Impact**: Receipt scanning and data synchronization require internet connectivity

#### 3. Currency Support
- **Limitation**: Currently optimized for Malaysian Ringgit (MYM) and limited multi-currency support
- **Impact**: International users may experience limited functionality

#### 4. Receipt Format Compatibility
- **Limitation**: OCR works best with standard printed receipts
- **Impact**: Non-standard formats may require manual entry

### Planned Future Enhancements

**1. AI-Powered Categorization**
- Implement machine learning to automatically categorize expenses based on merchant names and patterns
- Learn from user behavior to improve accuracy over time

**2. Advanced OCR**
- Enhanced OCR capabilities for handwritten receipts
- Support for multiple languages and receipt formats
- Improved accuracy for low-quality images

**3. Smart Budget Recommendations**
- AI-driven budget suggestions based on spending patterns
- Predictive analytics for future spending trends
- Personalized financial insights and tips

---

## Conclusion

The Finance Tracker application successfully addresses the core challenges of personal financial management by providing an intuitive, comprehensive solution for budget tracking, receipt digitization, and expense categorization by payment type. While there are current limitations, the roadmap for future enhancements positions the application for continued growth and improved user value.

The application's modular architecture and scalable design ensure that planned enhancements can be integrated seamlessly, providing users with an increasingly powerful tool for managing their personal finances effectively.

---
