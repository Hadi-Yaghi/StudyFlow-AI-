package com.studyflow.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterRequest {
    @NotBlank(message ="Name is required")
    @Size(min = 2 ,max =100 , message = "Name must be between 2 and 100 characters")
    private String name ;
    @NotBlank(message = "Email is Required")
    @Email(message = "Email is not valid")
    private String email;
    @NotBlank(message = "Password is Required")
    @Size(min = 6 ,max =100 , message = "password must be at  least 8 characters")
    private String password;
}
