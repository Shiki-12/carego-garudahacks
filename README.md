# Carego - Doctor & Patient Platform

A comprehensive Flutter-based application connecting patients with doctors, healthcare providers, and medical equipment rentals. This platform serves as a complete ecosystem for telehealth and home healthcare services.

## 🚀 Project Overview

Carego is a feature-rich mobile application designed to streamline healthcare access. It bridges the gap between patients seeking medical assistance and healthcare professionals or rental services.

### Key Features

- **Doctor Services**:
  - Search & filter doctors by specialization.
  - View detailed doctor profiles with ratings and availability.
  - Book appointments (future implementation: integrated with backend).

- **Caregiver Services**:
  - Browse and book certified caregivers for home care.
  - Supports scheduling by date and time.

- **Medical Equipment Rental**:
  - Catalog of medical equipment (wheelchairs, walkers, oxygen tanks).
  - Rental booking with duration selection.
  - Price calculation based on rental period.

- **User Management**:
  - Multi-role authentication (Patient, Doctor, Admin).
  - User profile management and account settings.

- **Communication**:
  - Real-time chat between patients and doctors (mocked with local data).

- **Wallet System**:
  - In-app wallet for managing transactions and payments.

- **Notifications**:
  - Push notifications for appointments, bookings, and messages.
  - Granular notification preferences.

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: `GetX` (Primary)
- **Routing**: `go_router`
- **HTTP Client**: `http`
- **Mapping**: `google_maps_flutter`
- **Icons**: `font_awesome_flutter`, `line_icons`, `flutter_svg`
- **UI Components**:
  - `flutter_rating_bar` for ratings.
  - Custom Material widgets and animations.

## 📂 Project Structure

The codebase follows a clean architecture pattern:

```
lib/
├── core/             # Core utilities, constants, themes, and helpers
├── data/             # Data layer (repositories, API services, mock data)
│   ├── api/          # API configuration and base service
│   ├── repositories/ # Repository implementations
│   └── mock/         # Mock data providers for all services
├── model.dart/       # Data models (Doctor, Appointment, Equipment, etc.)
├── presentation/     # UI Layer (Screens, Widgets, Controllers)
│   ├── auth/         # Login, Register, Forgot Password
│   ├── home/         # Home screens and main navigation
│   ├── doctors/      # Doctor listings and details
│   ├── booking/      # Appointment booking flows
│   ├── caregiver/     # Caregiver services
│   ├── rental/       # Medical equipment rental
│   ├── chat/         # Chat functionality
│   ├── wallet/       # Wallet and transaction management
│   └── settings/     # Profile, preferences, and support
├── routes/           # Navigation setup using go_router
├── services/         # External services and providers
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── notification_service.dart
└── widgets/          # Reusable UI components
```

## 🏁 Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK
- Android Studio / VS Code
- Chrome (for web testing)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd carego-garudahacks
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

Start the application on your desired platform:

```bash
# Run on Chrome
flutter run -d chrome

# Run on Android Emulator/Device
flutter run

# Run on iOS Simulator/Device
flutter run -d iphone
```

## 📝 Development Setup

### API Integration

The project currently uses mock data for most services (e.g., `lib/data/mock/mock_doctor_data.dart`). To integrate with the actual backend API:

1. Update `lib/core/config/api_config.dart` with your API base URL.
2. Refactor `ApiService` to use actual HTTP requests instead of mock data.
3. Ensure backend endpoints match the expected API contract.

### State Management

We use GetX for state management.
- **Controllers**: Located in `presentation/<feature>/controllers/`.
- **Bind**: Use `Get.put()` in the controller or `GetBuilder`/`Obx` in widgets to manage state.

## 🎨 Design System

The app follows a consistent design language:
- **Primary Color**: `#1497FF` (Vivid Blue)
- **Accent Color**: `#764BA2` (Purple)
- **Typography**: `Nunito` font family.
- **Screenshots**: Refer to the `screenshots/` directory for visual references.

## 📄 Documentation

- **Product Requirements Document (PRD)**: `docs/prd/`
- **Software Requirements Specification (SRS)**: `docs/srs/`
- **API Documentation**: `docs/api/`

## 👥 Team

- Baoogo
