import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class EditBidDto {
  @IsNumber()
  @Min(100, { message: 'Bid amount must be between 100 and 500,000.' })
  @Max(500000, { message: 'Bid amount must be between 100 and 500,000.' })
  amount: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
