# CSE341 Project: Priority-Queue
This is a project about a priority queue using Assembly Language on EMU8086.

Priority queue system where tasks are assigned different priorities, and the task with the highest priority is always processed first.

Segments:

(i) Use an array to store tasks along with their priority values. Each task is represented by a unique identifier, and each priority is an integer value.

(ii) Implement a stack to manage the priority queue. The stack should store the tasks in order of priority (highest priority at the top). Whenever a task is added, the stack should adjust to maintain the correct priority order.

(iii) Use macros and procedures to add and remove tasks from the queue, ensuring that tasks are processed in the correct order of priority. Handle scenarios where multiple tasks have the same priority by managing them in the order they were added.

Key Considerations:

Efficiently manage the stack to reorder tasks based on priority.

Macros and procedures should dynamically handle priority comparison and reordering, maintaining a robust queue structure
