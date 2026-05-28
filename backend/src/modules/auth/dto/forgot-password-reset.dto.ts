import { IsString, MinLength, Matches } from 'class-validator';

export class ForgotPasswordResetDto {
  @IsString()
  @Matches(/^(\+92|0092|92|0)?[3][0-9]{9}$/, {
    message: 'phone must be a valid Pakistani mobile number',
  })
  phone: string;

  @IsString()
  @Matches(/^[0-9]{4,10}$/, { message: 'otp must be 4–10 digits' })
  otp: string;

  @IsString()
  @MinLength(8, { message: 'newPassword must be at least 8 characters' })
  newPassword: string;
}
