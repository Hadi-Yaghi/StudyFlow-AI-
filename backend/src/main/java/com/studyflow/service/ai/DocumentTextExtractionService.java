package com.studyflow.service.ai;

import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xslf.usermodel.XMLSlideShow;
import org.apache.poi.xslf.usermodel.XSLFSlide;
import org.apache.poi.xslf.usermodel.XSLFShape;
import org.apache.poi.xslf.usermodel.XSLFTextShape;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Slf4j
@Service
public class DocumentTextExtractionService {

    public static final int MAX_TEXT_LENGTH_FOR_AI = 20000;

    public String extractText(InputStream inputStream, String filename, String mimeType) {
        if (inputStream == null) {
            return "";
        }

        String lowerName = filename != null ? filename.toLowerCase() : "";
        String lowerMime = mimeType != null ? mimeType.toLowerCase() : "";

        try {
            if (lowerName.endsWith(".pdf") || lowerMime.contains("pdf")) {
                return extractPdfText(inputStream);
            } else if (lowerName.endsWith(".docx") || lowerMime.contains("wordprocessingml")) {
                return extractDocxText(inputStream);
            } else if (lowerName.endsWith(".pptx") || lowerMime.contains("presentationml")) {
                return extractPptxText(inputStream);
            } else if (lowerName.endsWith(".txt") || lowerMime.contains("text/plain")) {
                return extractPlainText(inputStream);
            } else {
                log.warn("Unsupported document format for text extraction: filename={}, mime={}", filename, mimeType);
                return "";
            }
        } catch (Exception e) {
            log.error("Failed to extract text from {}: {}", filename, e.getMessage(), e);
            return "";
        }
    }

    private String extractPdfText(InputStream is) throws Exception {
        byte[] bytes = is.readAllBytes();
        try (PDDocument document = Loader.loadPDF(bytes)) {
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setSortByPosition(true);
            String raw = stripper.getText(document);
            return cleanAndNormalizeText(raw);
        }
    }

    private String extractDocxText(InputStream is) throws Exception {
        try (XWPFDocument doc = new XWPFDocument(is);
             XWPFWordExtractor extractor = new XWPFWordExtractor(doc)) {
            String raw = extractor.getText();
            return cleanAndNormalizeText(raw);
        }
    }

    private String extractPptxText(InputStream is) throws Exception {
        StringBuilder sb = new StringBuilder();
        try (XMLSlideShow ppt = new XMLSlideShow(is)) {
            int slideNum = 1;
            for (XSLFSlide slide : ppt.getSlides()) {
                sb.append("--- Slide ").append(slideNum++).append(" ---\n");
                for (XSLFShape shape : slide.getShapes()) {
                    if (shape instanceof XSLFTextShape textShape) {
                        String text = textShape.getText();
                        if (text != null && !text.isBlank()) {
                            sb.append(text).append("\n");
                        }
                    }
                }
                sb.append("\n");
            }
        }
        return cleanAndNormalizeText(sb.toString());
    }

    private String extractPlainText(InputStream is) throws Exception {
        String raw = new String(is.readAllBytes(), StandardCharsets.UTF_8);
        return cleanAndNormalizeText(raw);
    }

    public String cleanAndNormalizeText(String text) {
        if (text == null) {
            return "";
        }
        // Normalize line breaks and tabs
        String cleaned = text.replace("\r\n", "\n").replace('\r', '\n');
        // Remove excessive empty lines
        cleaned = cleaned.replaceAll("\n{3,}", "\n\n");
        // Trim leading/trailing whitespace
        cleaned = cleaned.trim();

        // If exceeds threshold, provide intelligent summary/truncation with header and tail sections
        if (cleaned.length() > MAX_TEXT_LENGTH_FOR_AI) {
            log.info("Document text length ({}) exceeds limit ({}). Chunking and extracting key sections.",
                    cleaned.length(), MAX_TEXT_LENGTH_FOR_AI);
            int headChars = (int) (MAX_TEXT_LENGTH_FOR_AI * 0.7);
            int tailChars = (int) (MAX_TEXT_LENGTH_FOR_AI * 0.3);

            return cleaned.substring(0, headChars)
                    + "\n\n[... content truncated for AI processing ...]\n\n"
                    + cleaned.substring(cleaned.length() - tailChars);
        }

        return cleaned;
    }
}
