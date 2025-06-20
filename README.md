# SplitTrack - Personal & Group Expense Tracker

SplitTrack is a modern, intuitive Flutter application designed to help users manage their personal finances and effortlessly split shared expenses with groups. Built with a clean UI and local data storage using Hive, it provides a seamless experience for tracking daily spending and settling group debts.

## ✨ Features

### Personal Expense Tracking
- **Add Expenses:** Easily add expenses with amount, date, category, and optional notes.
- **Categorize:** Organize spending into categories like Food, Travel, Shopping, and more.
- **Visualize Spending:** An interactive pie chart shows a summary of the current month's expenses by category.
- **Filter & Search:** Filter expenses by category or a specific date range.
- **Edit & Delete:** Swipe gestures allow for quick editing or deleting of any expense entry.

### Group Expense Splitting
- **Create Groups:** Make groups for any occasion (e.g., trips, roommates, dinners) and add members.
- **Shared Expenses:** Add expenses to a group, specifying who paid and for whom the expense was for.
- **Automatic Settlements:** The app automatically calculates who owes whom, providing a clear and simple settlement summary.
- **Manage Groups:** Edit group details or delete groups you no longer need.

### Bonus Features Implemented
- **PDF Reports:** Export a detailed PDF report of your personal expenses directly from the app.
- **Currency Selection:** Choose your preferred currency from a list in the settings.
- **Light/Dark Mode:** Switch between Light, Dark, and System default themes.
- **Interactive Login Page:** A beautiful, animated (non-functional) login screen to welcome the user.

## 🛠️ Tech Stack
- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Hive
- **PDF Generation:** `pdf` & `path_provider`
- **Dependency Management:** Pub

## 🚀 How to Run

To get a local copy up and running, follow these simple steps.

### Prerequisites
- Flutter SDK installed: [Flutter Docs](https://flutter.dev/docs/get-started/install)
- An editor like VS Code or Android Studio.
- An Android emulator or a physical device.

### Installation & Execution
1.  Clone the repo or download the source code.
2.  Open your terminal in the project's root directory.
3.  Get the dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the app:
    ```sh
    flutter run
    ```

## 🐛 Known Bugs or Future Features

### Known Issues
- **Performance Warnings:** On some devices, the initial load may show "Skipped frames" warnings in the debug console. The app's performance remains stable during use.
- **Build Warnings:** Gradle may show warnings about an obsolete Java version, which does not affect the app's functionality.

### Future Features
- **Firebase Sync:** Implement Firebase Authentication and Firestore to sync data across multiple devices.
- **Notifications:** Add local notifications to remind users about pending settlements.
- **Bar Charts:** Add a bar chart view for another way to visualize monthly expenses.

## 📸 Screenshots

*(You can add your app screenshots here)*

---
Made with ❤️ by a Flutter developer.
