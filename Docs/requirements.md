# StudyFlow AI — Software Requirements

## 1. Project Overview

**Project Name:** StudyFlow AI  
**Platform:** Android Mobile Application

### Purpose

StudyFlow AI is a smart study-planning application designed to help students organize their study time automatically.

Instead of functioning as a traditional task manager, StudyFlow considers upcoming deadlines, estimated workload, course difficulty, task importance, and the student's available study time to generate a personalized study schedule.

A key feature of StudyFlow is adaptive scheduling. When a student misses or skips a study session, the system recalculates the remaining workload and reorganizes future study sessions while considering upcoming deadlines and available study time.

---

## 2. Target User

The primary user of StudyFlow is a:

**Student**

For the initial version (MVP), the application will focus exclusively on students. Teacher and administrator functionality is outside the initial scope.

---

## 3. Core Application Flow

1. Student creates an account and logs in.
2. Student creates a semester.
3. Student adds courses.
4. Student adds exams, assignments, quizzes, projects, and other deadlines.
5. Student provides estimated study time, difficulty, and importance.
6. Student defines their weekly study availability.
7. StudyFlow calculates priorities for upcoming academic work.
8. StudyFlow generates a personalized study schedule.
9. Student follows the generated study sessions.
10. Student marks sessions as completed, skipped, or missed.
11. StudyFlow recalculates and reschedules unfinished work when necessary.
12. Student can monitor their study progress.

---

## 4. Functional Requirements

### Authentication

**FR-01:** The student shall be able to create an account.

**FR-02:** The student shall be able to securely log in to their account.

### Semester Management

**FR-03:** The student shall be able to create, view, update, and manage semesters.

### Course Management

**FR-04:** The student shall be able to create, view, update, and delete courses associated with a semester.

### Academic Deadlines

**FR-05:** The student shall be able to create and manage exams, assignments, quizzes, projects, and other academic deadlines.

**FR-06:** The student shall be able to specify a deadline date, estimated study time, difficulty, and importance for academic work.

### Study Availability

**FR-07:** The student shall be able to define the days and times during which they are available to study.

### Smart Scheduling

**FR-08:** The system shall calculate priorities for academic work based on factors such as deadline proximity, difficulty, importance, and remaining workload.

**FR-09:** The system shall automatically generate study sessions based on priorities and the student's available study time.

### Study Sessions

**FR-10:** The student shall be able to view today's and upcoming study sessions.

**FR-11:** The student shall be able to start and complete a study session.

**FR-12:** The student shall be able to mark a study session as skipped or missed.

### Adaptive Rescheduling

**FR-13:** The system shall automatically recalculate and redistribute unfinished study work when a session is missed or skipped.

### Progress Tracking

**FR-14:** The student shall be able to view their study progress and completed study sessions.

### Monetization

**FR-15:** The application shall support premium functionality through RevenueCat.

---

## 5. MVP Success Criteria

The initial version of StudyFlow will be considered functional when a student can:

1. Create an account and log in.
2. Create a semester and courses.
3. Add academic deadlines and estimated workloads.
4. Define available study times.
5. Generate a personalized study schedule.
6. Complete or miss generated study sessions.
7. Have missed study work automatically rescheduled.
8. View basic study progress.

The core scheduling and rescheduling functionality must work before additional advanced features are introduced.

---

## 6. Future Features

The following features are planned for later development and are not required for the initial MVP:

- AI Study Coach
- AI-generated quizzes
- Weak-topic detection
- Adaptive learning based on quiz performance
- Syllabus/document analysis
- Smart push notifications
- Advanced study analytics
- Gamification and achievements
- Social or collaborative study features