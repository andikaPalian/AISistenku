export interface RegisterDTO {
  name: string;
  email: string;
  password: string;
  businessName: string;
  businessAddress: string;
  businessPhone: string;
}

export interface LoginDTO {
  email: string;
  password: string;
}
