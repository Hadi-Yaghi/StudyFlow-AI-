package com.studyflow.service.storage.impl;

import com.studyflow.service.storage.FileStorageService;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.*;
import java.util.UUID;

@Slf4j
@Service
public class LocalStorageServiceImpl implements FileStorageService {

    @Value("${studyflow.files.upload-dir:./uploads/materials}")
    private String uploadDirProperty;

    private Path rootLocation;

    @PostConstruct
    public void init() {
        try {
            this.rootLocation = Paths.get(uploadDirProperty).toAbsolutePath().normalize();
            Files.createDirectories(this.rootLocation);
            log.info("Initialized local file storage at: {}", this.rootLocation);
        } catch (IOException e) {
            log.error("Could not initialize storage directory: {}", e.getMessage(), e);
            throw new RuntimeException("Could not initialize storage directory", e);
        }
    }

    @Override
    public String store(MultipartFile file, String subDirectory) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Cannot store empty file.");
        }

        String rawFilename = StringUtils.cleanPath(file.getOriginalFilename() != null ? file.getOriginalFilename() : "file");
        if (rawFilename.contains("..")) {
            throw new IllegalArgumentException("Cannot store file with relative path outside current directory: " + rawFilename);
        }

        String extension = "";
        int dotIndex = rawFilename.lastIndexOf('.');
        if (dotIndex >= 0) {
            extension = rawFilename.substring(dotIndex);
        }

        String uniqueFilename = UUID.randomUUID() + extension;

        try {
            Path targetDir = this.rootLocation;
            if (subDirectory != null && !subDirectory.trim().isEmpty()) {
                String cleanSub = StringUtils.cleanPath(subDirectory.trim());
                targetDir = this.rootLocation.resolve(cleanSub).normalize();
                if (!targetDir.startsWith(this.rootLocation)) {
                    throw new SecurityException("Cannot store file outside configured root directory.");
                }
                Files.createDirectories(targetDir);
            }

            Path destinationFile = targetDir.resolve(uniqueFilename).normalize();
            if (!destinationFile.startsWith(this.rootLocation)) {
                throw new SecurityException("Cannot store file outside current directory.");
            }

            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
            }

            log.info("Stored file '{}' as '{}'", rawFilename, destinationFile);
            // Return relative storage key
            return this.rootLocation.relativize(destinationFile).toString().replace('\\', '/');
        } catch (IOException e) {
            log.error("Failed to store file {}: {}", rawFilename, e.getMessage(), e);
            throw new RuntimeException("Failed to store file: " + rawFilename, e);
        }
    }

    @Override
    public Resource loadAsResource(String storageKey) {
        try {
            Path file = this.rootLocation.resolve(storageKey).normalize();
            if (!file.startsWith(this.rootLocation)) {
                throw new SecurityException("Cannot access file outside current directory.");
            }

            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() || resource.isReadable()) {
                return resource;
            } else {
                throw new RuntimeException("Could not read file: " + storageKey);
            }
        } catch (MalformedURLException e) {
            throw new RuntimeException("Could not read file: " + storageKey, e);
        }
    }

    @Override
    public void delete(String storageKey) {
        if (storageKey == null || storageKey.trim().isEmpty()) {
            return;
        }
        try {
            Path file = this.rootLocation.resolve(storageKey).normalize();
            if (!file.startsWith(this.rootLocation)) {
                throw new SecurityException("Cannot delete file outside current directory.");
            }
            Files.deleteIfExists(file);
            log.info("Deleted stored file: {}", storageKey);
        } catch (IOException e) {
            log.warn("Could not delete file {}: {}", storageKey, e.getMessage());
        }
    }
}
