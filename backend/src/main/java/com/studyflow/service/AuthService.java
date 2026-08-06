package com.studyflow.service;

import com.studyflow.dto.request.LoginRequest;
import com.studyflow.dto.request.RegisterRequest;
import com.studyflow.dto.response.AuthResponse;
import com.studyflow.entity.User;
import com.studyflow.repository.UserRepository;
import com.studyflow.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository =  userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;

    }
    public AuthResponse register (RegisterRequest request){
        String email = request.getEmail().trim().toLowerCase();
        if(userRepository.existsByEmail(email)){
            throw new RuntimeException("Email already exists");

        }
        User  user = User.builder().name(request.getName().trim())
                .email(email)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .build();
        User  savedUser = userRepository.save(user);
        String token = jwtService.generateToken(email);

        return new AuthResponse(
                token,savedUser.getId(),
                savedUser.getName()
                , savedUser.getEmail()

        );
    }
    public  AuthResponse login(LoginRequest request){
        String email = request.getEmail().trim().toLowerCase();
        if(!userRepository.existsByEmail(email)){
            throw new RuntimeException("Email not found");
        }
        User  user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Invalid email or  password"));
        if(!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())){
            throw new IllegalArgumentException("Invalid email or password");
        }
        String token = jwtService.generateToken(email);
        return new AuthResponse (token,user.getId(),user.getName(),user.getEmail());
    }
}
