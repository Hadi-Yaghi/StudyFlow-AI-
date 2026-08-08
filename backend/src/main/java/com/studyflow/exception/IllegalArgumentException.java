import com.studyflow.exception.ApiError;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<ApiError> handleIllegalArgument(
        IllegalArgumentException ex,
        HttpServletRequest request) {

    ApiError error = ApiError.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.BAD_REQUEST.value())
            .error(HttpStatus.BAD_REQUEST.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();

    return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(error);
}

void main() {
}