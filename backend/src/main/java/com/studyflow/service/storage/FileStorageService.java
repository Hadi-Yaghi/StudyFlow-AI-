package com.studyflow.service.storage;

import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {

    String store(MultipartFile file, String subDirectory);

    Resource loadAsResource(String storageKey);

    void delete(String storageKey);
}
