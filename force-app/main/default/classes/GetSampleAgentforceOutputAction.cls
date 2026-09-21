/**
 * GetSampleAgentforceOutputAction — invocable action for the "LWC Example
 * Library" demo agent. Returns a deterministic sample payload for display as
 * a Custom Lightning Type renderer (c/sampleAgentforceOutputLWC via
 * sampleAgentforceOutputCLT). Exists purely to make the template scaffold
 * example testable end-to-end with real utterances.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-20.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetSampleAgentforceOutputAction {

    @InvocableMethod(
        label='Get Sample Agentforce Output'
        description='Returns a sample title, message, and item list to display as a visual card. Template action for the reusable inline-LWC scaffold.')
    global static List<GetSampleAgentforceOutputResult> get(List<GetSampleAgentforceOutputRequest> requests) {
        List<GetSampleAgentforceOutputResult> responses = new List<GetSampleAgentforceOutputResult>();
        for (GetSampleAgentforceOutputRequest req : requests) {
            responses.add(buildOutput(req.topic));
        }
        return responses;
    }

    private static GetSampleAgentforceOutputResult buildOutput(String topic) {
        String subject = String.isBlank(topic) ? 'the scaffold library' : topic;

        SampleAgentforceOutputWrapper output = new SampleAgentforceOutputWrapper();
        output.title = 'Sample Agentforce Output';
        output.message = 'This is a template card about ' + subject + '.';
        output.items = new List<String>{ 'Works on Web', 'Works on Mobile', 'Duplicate me to start a new example' };

        GetSampleAgentforceOutputResult resp = new GetSampleAgentforceOutputResult();
        resp.output = output;
        resp.summary = output.title + ': ' + output.message;
        return resp;
    }
}
