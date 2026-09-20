package com.studyflow.dto.ai;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiPlanRequest {

    private List<Long> materialIds;
}
