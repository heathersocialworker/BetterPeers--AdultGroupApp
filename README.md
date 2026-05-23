# BetterEDU Resources

BetterEDU Resources is an innovative mobile application that caters to students' mental well-being and academic success. The intuitive design of the application, complemented by a vast catalog of resources, enables students to access essential services in a wide array of needs areas.

## Overview

At BetterEDU Resources, we pride ourselves on helping students achieve a healthy state of mind by providing access to many resources for financial, mental health, and educational services for the next generation.

Currently, BetterEDU Resources focuses on targeted resources for students in both Arizona and California but aspires to scale its work throughout the West Coast and beyond to ensure students nationwide have the supports they need to succeed.

## Key Features

- **Financial Assistance**: Access information on scholarships, grants, and budgeting resources designed to make living easier for students.
- **Emergency Support**: Get immediate contact numbers for hotlines and mental health services when urgently needed.
- **Self-Care Tools**: Engagement through curated resources on mental wellbeing, mindfulness, and stress management.
- **Academic Resources**: Learn about stress-reduction initiatives, tutoring availability, and resources designed to support improved academic performance.
- **Customizable Profiles**: Bookmark favourite resources, define your location, and tailor your settings to suit your unique needs and objectives.

## Technical Stack

- **Framework**: SwiftUI
- **Platform**: iOS
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **Storage**: Firebase Storage
- **Minimum iOS Version**: iOS 15.0+

## Project Structure

```
BetterEDU Resources/
├── Views/                  # UI Components
│   ├── HomePageView       # Main landing page
│   ├── ProfileView        # User profile management
│   ├── ResourcesView      # Resource browsing
│   ├── LoginView          # Authentication
│   └── ...                # Other view components
├── General/               # Core functionality
│   ├── AuthViewModel      # Authentication logic
│   ├── NavView           # Navigation component
│   └── ...               # Other core components
├── Utilities/            # Helper functions
├── Extensions/           # Swift extensions
└── Assets.xcassets/      # Image and media assets
```

## Setup Instructions

1. **Prerequisites**
   - Xcode 14.0 or later
   - iOS 15.0+ device or simulator
   - CocoaPods (for Firebase dependencies)

2. **Installation**
   ```bash
   # Clone the repository
   git clone [repository-url]
   
   # Navigate to project directory
   cd BetterEDU-Resources
   
   # Install dependencies
   pod install
   
   # Open the workspace
   open BetterEDU\ Resources.xcworkspace
   ```

3. **Firebase Setup**
   - Add your `GoogleService-Info.plist` to the project
   - Enable Authentication, Firestore, and Storage in Firebase Console
   - Configure Firebase rules for security

## Features in Development

- Expansion to more states and regions
- Enhanced resource recommendation system
- Community features and peer support
- Integration with university-specific resources
- Offline resource access

## Contributing

We welcome contributions to BetterEDU Resources! If you'd like to contribute:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any queries or support, please reach out to [contact information]
