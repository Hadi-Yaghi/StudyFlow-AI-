# StudyFlow AI — System Architecture

## 1. Overview

StudyFlow AI is a mobile study-planning application designed to help students organize courses, academic deadlines, study availability, and study sessions.

The main feature of StudyFlow is its intelligent scheduling engine.

Instead of requiring students to manually create every study session, StudyFlow analyzes:

- Academic deadlines
- Deadline urgency
- Course difficulty
- Task importance
- Estimated study workload
- Remaining workload
- Student availability
- Existing study sessions

The system then generates a personalized study plan.

If a student misses a study session, StudyFlow can attempt to reschedule the remaining workload into another available time slot.

The application also integrates RevenueCat for premium subscription management.

---

# 2. Technology Stack

## Mobile Application

- Flutter
- Dart
- REST API communication
- RevenueCat Flutter SDK

## Backend

- Java
- Spring Boot
- Spring Web
- Spring Security
- Spring Data JPA
- Hibernate
- JWT Authentication
- Bean Validation

## Database

- PostgreSQL

## Monetization

- RevenueCat
- Google Play Billing

## Development Tools

- Git
- GitHub
- IntelliJ IDEA
- Android Studio
- Postman
- draw.io
- PlantUML

---

# 3. High-Level Architecture

The system follows a client-server architecture.

```text
┌───────────────────────────────┐
│                               │
│      Flutter Mobile App       │
│                               │
│  - User Interface             │
│  - State Management           │
│  - API Client                 │
│  - RevenueCat SDK             │
│                               │
└───────────────┬───────────────┘
                │
                │ HTTPS
                │ REST / JSON
                │
                ▼
┌───────────────────────────────┐
│                               │
│      Spring Boot REST API     │
│                               │
│  - Authentication             │
│  - Controllers                │
│  - Business Services          │
│  - Validation                 │
│  - Scheduling Engine          │
│  - Security                   │
│                               │
└───────────────┬───────────────┘
                │
                │ Spring Data JPA
                │ Hibernate
                │
                ▼
┌───────────────────────────────┐
│                               │
│          PostgreSQL           │
│                               │
│  - Users                      │
│  - Semesters                  │
│  - Courses                    │
│  - Deadlines                  │
│  - Availability               │
│  - Study Plans                │
│  - Study Sessions             │
│  - Subscriptions              │
│                               │
└───────────────────────────────┘
```

RevenueCat is integrated separately through the mobile application:

```text
Flutter App
     │
     ▼
RevenueCat SDK
     │
     ├──────────────► RevenueCat
     │
     └──────────────► Google Play
```

---

# 4. Flutter Mobile Application

The Flutter application is the client-facing part of StudyFlow.

It is responsible for displaying information to the student and communicating with the Spring Boot backend.

The Flutter application should not contain the main scheduling business logic.

The scheduling logic remains on the backend.

## Main Responsibilities

The Flutter application handles:

- User registration
- User login
- Semester management
- Course management
- Deadline management
- Study availability management
- Study-plan visualization
- Study-session tracking
- Marking sessions as completed
- Marking sessions as missed
- Displaying progress
- Premium subscription interface
- RevenueCat purchases

---

# 5. Spring Boot Backend

The Spring Boot application provides the REST API used by the Flutter application.

The backend contains the main business logic of StudyFlow.

The backend follows a layered architecture.

```text
Controller
     │
     ▼
Service
     │
     ▼
Repository
     │
     ▼
PostgreSQL
```

Scheduling functionality introduces an additional domain layer:

```text
Controller
     │
     ▼
Service
     │
     ▼
Scheduling Engine
     │
     ▼
Repository
     │
     ▼
PostgreSQL
```

---

# 6. Controller Layer

Controllers expose REST API endpoints.

Their responsibilities should remain limited to:

- Receiving HTTP requests
- Validating request data
- Calling the appropriate service
- Returning HTTP responses

Controllers should not contain complex business logic.

Planned controllers include:

```text
AuthController
SemesterController
CourseController
DeadlineController
StudyAvailabilityController
StudyPlanController
StudySessionController
SubscriptionController
```

Example request:

```text
POST /api/study-plans/generate
```

The controller receives the request and delegates the actual plan generation to the appropriate service.

---

# 7. Service Layer

The service layer contains application business logic.

Planned services include:

```text
AuthService
SemesterService
CourseService
DeadlineService
StudyAvailabilityService
StudyPlanService
StudySessionService
SubscriptionService
```

For example:

```text
StudyPlanController
        │
        ▼
StudyPlanService
        │
        ▼
SchedulingService
```

The service layer coordinates repositories and other domain services.

---

# 8. Repository Layer

Repositories provide database access.

Spring Data JPA will be used to implement the repository layer.

Planned repositories:

```text
UserRepository
SemesterRepository
CourseRepository
DeadlineRepository
StudyAvailabilityRepository
StudyPlanRepository
StudySessionRepository
SubscriptionRepository
```

Repositories should primarily be responsible for retrieving and storing data.

Business logic should not be placed inside repositories.

---

# 9. Scheduling Engine

The Scheduling Engine is one of the core components of StudyFlow.

Its purpose is to automatically transform academic deadlines and student availability into scheduled study sessions.

The initial scheduling package may contain:

```text
scheduling/
│
├── SchedulingService
├── PriorityCalculator
├── SlotFinder
└── ReschedulingService
```

---

# 10. Priority Calculator

The `PriorityCalculator` determines which deadlines should receive study time first.

Priority can be influenced by:

- Time remaining before the deadline
- Deadline importance
- Course difficulty
- Remaining required study time

Conceptually:

```text
Deadline
   │
   ├── Due Date
   ├── Importance
   ├── Course Difficulty
   └── Remaining Workload
            │
            ▼
     PriorityCalculator
            │
            ▼
       Priority Score
```

A higher priority score indicates that the deadline should receive study time sooner.

The exact priority formula will be defined and tested during implementation.

---

# 11. Remaining Workload

Each deadline contains:

```text
estimatedMinutes
completedMinutes
```

The remaining workload can be calculated as:

```text
remainingMinutes =
estimatedMinutes - completedMinutes
```

Example:

```text
Database Midterm

Estimated study time:
480 minutes

Completed:
180 minutes

Remaining:
300 minutes
```

The scheduling engine must allocate approximately 300 additional minutes before the deadline.

---

# 12. Slot Finder

The `SlotFinder` determines where study sessions can be placed.

It analyzes:

- Student availability
- Existing study sessions
- Deadline date
- Current date and time
- Required session duration

Example availability:

```text
Monday
18:00 - 21:00

Tuesday
19:00 - 22:00

Wednesday
18:00 - 20:00
```

The Slot Finder must avoid overlapping sessions.

Conceptually:

```text
Study Availability
        +
Existing Sessions
        +
Deadline Constraints
        │
        ▼
    SlotFinder
        │
        ▼
Available Study Slots
```

---

# 13. Scheduling Service

The `SchedulingService` coordinates study-plan generation.

The basic process is:

```text
Get active semester
        │
        ▼
Get courses
        │
        ▼
Get deadlines
        │
        ▼
Get availability
        │
        ▼
Calculate remaining workload
        │
        ▼
Calculate priorities
        │
        ▼
Find available slots
        │
        ▼
Generate Study Sessions
        │
        ▼
Create Study Plan
        │
        ▼
Save to PostgreSQL
```

---

# 14. Automatic Rescheduling

StudyFlow should adapt when a student misses a scheduled study session.

Example:

```text
Monday
18:00 - 19:00

Database Study Session

MISSED
```

The system should attempt to move the remaining workload to another valid slot.

The rescheduling process is:

```text
Missed Study Session
        │
        ▼
Mark Session MISSED
        │
        ▼
Determine Remaining Workload
        │
        ▼
Check Deadline
        │
        ▼
Recalculate Priority
        │
        ▼
Find Future Availability
        │
        ▼
Check Existing Sessions
        │
        ▼
Find New Slot
        │
        ├──────────── YES ────────────┐
        │                             │
        ▼                             │
Create Replacement Session           │
        │                             │
        ▼                             │
Save Updated Schedule                 │
                                      │
        └──────────── NO ─────────────┘
                      │
                      ▼
              Scheduling Conflict
```

The user can then be informed if StudyFlow cannot safely fit all remaining work before the deadline.

---

# 15. PostgreSQL Database

PostgreSQL stores persistent StudyFlow data.

The main tables are:

```text
users
semesters
courses
deadlines
study_availability
study_plans
study_sessions
subscriptions
```

The detailed database structure is documented separately in:

```text
docs/database/database-schema.md
```

---

# 16. Authentication

StudyFlow will use token-based authentication.

The planned authentication flow is:

```text
Student
   │
   ▼
Flutter
   │
   │ Email + Password
   ▼
Spring Boot
   │
   ▼
Authenticate User
   │
   ▼
Generate JWT
   │
   ▼
Flutter
```

Future protected requests include the JWT:

```text
Authorization: Bearer <token>
```

Spring Security validates the token before protected API endpoints are accessed.

---

# 17. Security Package

The planned backend security package is:

```text
security/
│
├── SecurityConfig
├── JwtService
└── JwtAuthenticationFilter
```

Passwords must never be stored as plain text.

Passwords will be securely hashed before being stored in PostgreSQL.

---

# 18. RevenueCat Integration

RevenueCat will manage StudyFlow's premium entitlement and subscription state.

The Flutter application integrates the RevenueCat SDK.

Conceptual purchase flow:

```text
Student
   │
   ▼
Flutter App
   │
   ▼
RevenueCat SDK
   │
   ▼
Google Play
   │
   ▼
Purchase
   │
   ▼
RevenueCat
   │
   ▼
CustomerInfo / Entitlement
   │
   ▼
Flutter App
   │
   ▼
Premium Features
```

A planned entitlement name is:

```text
premium
```

The exact products, packages, and pricing will be configured later.

---

# 19. Subscription Data

StudyFlow may maintain a local representation of subscription state for backend authorization and application logic.

The `subscriptions` table contains information such as:

```text
user_id
revenuecat_customer_id
entitlement
product_id
status
expires_at
updated_at
```

RevenueCat remains the authoritative source for purchase/entitlement information.

The backend should not trust arbitrary subscription-state values sent by the client.

---

# 20. DTO Layer

Entities should not normally be exposed directly through REST endpoints.

StudyFlow will use DTOs.

The package structure will include:

```text
dto/
│
├── request/
│
└── response/
```

Examples:

```text
RegisterRequest
LoginRequest
CreateSemesterRequest
CreateCourseRequest
CreateDeadlineRequest
CreateAvailabilityRequest
GenerateStudyPlanRequest
CompleteStudySessionRequest
```

Possible response DTOs include:

```text
AuthResponse
SemesterResponse
CourseResponse
DeadlineResponse
StudyPlanResponse
StudySessionResponse
```

This keeps the API contract separate from the persistence model.

---

# 21. Exception Handling

StudyFlow will use centralized exception handling.

Planned structure:

```text
exception/
│
├── GlobalExceptionHandler
├── ResourceNotFoundException
├── ValidationException
└── SchedulingException
```

Possible API errors include:

```text
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
500 Internal Server Error
```

For example, if the scheduling engine cannot find enough available time before a deadline, the API may return an appropriate scheduling conflict response.

---

# 22. Planned Backend Package Structure

```text
src/main/java/com/studyflow/
│
├── StudyFlowApplication.java
│
├── config/
│
├── controller/
│   ├── AuthController.java
│   ├── SemesterController.java
│   ├── CourseController.java
│   ├── DeadlineController.java
│   ├── StudyAvailabilityController.java
│   ├── StudyPlanController.java
│   ├── StudySessionController.java
│   └── SubscriptionController.java
│
├── service/
│   ├── AuthService.java
│   ├── SemesterService.java
│   ├── CourseService.java
│   ├── DeadlineService.java
│   ├── StudyAvailabilityService.java
│   ├── StudyPlanService.java
│   ├── StudySessionService.java
│   └── SubscriptionService.java
│
├── scheduling/
│   ├── SchedulingService.java
│   ├── PriorityCalculator.java
│   ├── SlotFinder.java
│   └── ReschedulingService.java
│
├── repository/
│   ├── UserRepository.java
│   ├── SemesterRepository.java
│   ├── CourseRepository.java
│   ├── DeadlineRepository.java
│   ├── StudyAvailabilityRepository.java
│   ├── StudyPlanRepository.java
│   ├── StudySessionRepository.java
│   └── SubscriptionRepository.java
│
├── entity/
│   ├── User.java
│   ├── Semester.java
│   ├── Course.java
│   ├── Deadline.java
│   ├── StudyAvailability.java
│   ├── StudyPlan.java
│   ├── StudySession.java
│   └── Subscription.java
│
├── dto/
│   ├── request/
│   └── response/
│
├── enums/
│   ├── DeadlineType.java
│   ├── DeadlineStatus.java
│   ├── StudyPlanStatus.java
│   ├── StudySessionStatus.java
│   └── SubscriptionStatus.java
│
├── security/
│   ├── SecurityConfig.java
│   ├── JwtService.java
│   └── JwtAuthenticationFilter.java
│
└── exception/
    ├── GlobalExceptionHandler.java
    ├── ResourceNotFoundException.java
    ├── ValidationException.java
    └── SchedulingException.java
```

---

# 23. Main Domain Model

StudyFlow contains the following primary domain entities:

```text
User
Semester
Course
Deadline
StudyAvailability
StudyPlan
StudySession
Subscription
```

The primary relationships are:

```text
User
 ├── Semester
 │     └── Course
 │           ├── Deadline
 │           └── StudySession
 │
 ├── StudyAvailability
 ├── StudyPlan
 │     └── StudySession
 │
 └── Subscription
```

---

# 24. Main StudyFlow Workflow

The overall user workflow is:

```text
Register / Login
       │
       ▼
Create Semester
       │
       ▼
Add Courses
       │
       ▼
Add Deadlines
       │
       ▼
Define Study Availability
       │
       ▼
Generate Study Plan
       │
       ▼
Scheduling Engine
       │
       ▼
Study Sessions Generated
       │
       ▼
Student Follows Schedule
       │
       ├──────────────┐
       │              │
       ▼              ▼
   Completed        Missed
       │              │
       ▼              ▼
Update Progress   Auto Reschedule
       │              │
       └──────┬───────┘
              ▼
        Updated Plan
```

---

# 25. MVP Architecture Goals

The first working version should prioritize:

1. User authentication
2. Semester management
3. Course management
4. Deadline management
5. Study availability
6. Study-plan generation
7. Study-session tracking
8. Missed-session rescheduling
9. RevenueCat integration
10. A polished Flutter user experience

Features outside the MVP should not delay completion of the core scheduling system.

---

# 26. Design Principles

StudyFlow development should follow these principles:

### Separation of Concerns

Controllers, services, repositories, and scheduling components should have clearly separated responsibilities.

### Thin Controllers

Controllers should delegate business logic to services.

### DTO-Based API

REST endpoints should communicate using request and response DTOs rather than directly exposing persistence entities.

### Backend-Owned Scheduling Logic

The scheduling algorithm should live in Spring Boot rather than Flutter.

### Testable Scheduling Components

Components such as `PriorityCalculator` and `SlotFinder` should be designed so they can be unit tested independently.

### Secure Authentication

Passwords must be hashed and protected endpoints must require authentication.

### Server-Side Ownership Validation

Every user-owned resource must be validated on the backend.

A user must never be able to access another user's semesters, courses, deadlines, study plans, or sessions simply by changing an ID in an API request.

### Incremental Development

The application should be implemented feature-by-feature instead of generating the entire codebase at once.

---

# 27. Architecture Summary

The final architecture can be summarized as:

```text
                    STUDENT
                       │
                       ▼
                ┌─────────────┐
                │   Flutter   │
                │ Mobile App  │
                └──────┬──────┘
                       │
                 REST / HTTPS
                       │
                       ▼
              ┌─────────────────┐
              │   Spring Boot   │
              │     REST API    │
              └────────┬────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
     Business      Scheduling    Security
      Services        Engine       / JWT
          │            │
          └─────┬──────┘
                │
                ▼
          Repositories
                │
                ▼
           PostgreSQL


Flutter
   │
   ▼
RevenueCat SDK
   │
   ├──── RevenueCat
   │
   └──── Google Play
```

StudyFlow therefore separates:

- Mobile presentation
- REST API
- Business logic
- Scheduling logic
- Persistence
- Authentication
- Monetization

This architecture provides a foundation for implementing and extending the application while keeping the codebase maintainable and testable.