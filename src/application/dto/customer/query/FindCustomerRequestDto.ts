import { z } from 'zod';

/**
 * Allowed combinations:
 * - dateOfBirth
 * - dateOfBirth + lastName
 * - lastName
 * - lastName + firstName
 * - dateOfBirth + lastName + firstName
 */
export const findCustomerRequestSchema = z
  .object({
    firstName: z.string().optional(),
    lastName: z.string().optional(),
    dateOfBirth: z.string().optional() // 'YYYY-MM-DD'
  })
  .superRefine((value, ctx) => {
    const hasDob = !!value.dateOfBirth;
    const hasLast = !!value.lastName;
    const hasFirst = !!value.firstName;

    const valid =
      (hasDob && !hasLast && !hasFirst) ||
      (hasDob && hasLast && !hasFirst) ||
      (!hasDob && hasLast && !hasFirst) ||
      (!hasDob && hasLast && hasFirst) ||
      (hasDob && hasLast && hasFirst);

    if (!valid) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          'Invalid search. Use one of: DOB; DOB + last name; last name; last + first; DOB + last + first.'
      });
    }
  });

export type FindCustomerRequestDto = z.infer<typeof findCustomerRequestSchema>;
