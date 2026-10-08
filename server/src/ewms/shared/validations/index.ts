import { z } from 'zod';
import {
  Role,
  TaskStatus,
  TaskPriority,
  AttendanceStatus,
  EmploymentType,
  WorkMode,
  LeaveType,
} from '../enums';

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const CreateEmployeeSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  role: z.nativeEnum(Role),
  departmentId: z.string().uuid().optional(),
  teamId: z.string().uuid().optional(),
  managerId: z.string().uuid().optional(),
  employmentType: z.nativeEnum(EmploymentType).default(EmploymentType.FULL_TIME),
  workMode: z.nativeEnum(WorkMode).default(WorkMode.HYBRID),
  weeklyCapacityHours: z.number().positive().default(40),
  salary: z.number().positive().optional(),
  bankAccount: z.string().optional(),
  taxId: z.string().optional(),
});

export const CreateTaskSchema = z.object({
  title: z.string().min(1).max(255),
  description: z.string().optional(),
  projectId: z.string().uuid(),
  assigneeId: z.string().uuid().optional(),
  priority: z.nativeEnum(TaskPriority).default(TaskPriority.MEDIUM),
  estimatedHours: z.number().positive(),
  deadline: z.string().datetime().optional(),
  dependsOnTaskIds: z.array(z.string().uuid()).default([]),
});

export const UpdateTaskStatusSchema = z.object({
  status: z.nativeEnum(TaskStatus),
  reason: z.string().optional(),
});

export const StartTimeSessionSchema = z.object({
  taskId: z.string().uuid(),
  notes: z.string().optional(),
});

export const ClockAttendanceSchema = z.object({
  workMode: z.nativeEnum(WorkMode).default(WorkMode.HYBRID),
  notes: z.string().optional(),
});
