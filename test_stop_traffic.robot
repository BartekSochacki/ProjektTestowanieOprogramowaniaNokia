*** Settings ***
Documentation   Testy funkcjonalności zakończenia przesyłania danych w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}             http://localhost:8000

*** Keywords ***
Setup API Session
    Create Session    epc    ${BASE_URL}
    POST On Session    epc    /reset    expected_status=any

Attach UE
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Add Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    &{body}=        Create Dictionary    bearer_id=${bearer_id}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${kbps}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Stop Traffic
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

Get UE State
    [Arguments]    ${ue_id}
    ${response}=    GET On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Status Code Should Be
    [Arguments]    ${response}    ${expected}
    Should Be Equal As Integers    ${response.status_code}    ${expected}

Status Code Should Be Error
    [Arguments]    ${response}
    Should Be True    ${response.status_code} >= 400

*** Test Cases ***
TC01 Zakonczenie Transferu Dla Konkretnego Bearera
    [Documentation]    Transfer danych dla konkretnego bearera można poprawnie zakończyć.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    ${resp}=    Stop Traffic    10    9
    Status Code Should Be    ${resp}    200

TC02 Zakonczenie Transferu Dla Wszystkich Bearerow UE
    [Documentation]    Transfer można zakończyć dla wszystkich bearerów jednego UE, każdy wraca do stanu nieaktywnego.
    [Setup]    Setup API Session
    Attach UE    10
    Add Bearer    10    3
    Start Traffic    10    9    500
    Start Traffic    10    3    500
    ${state_before}=    Get UE State    10
    ${bearers}=    Get Dictionary Keys    ${state_before.json()}[bearers]
    FOR    ${bearer_id}    IN    @{bearers}
        Stop Traffic    10    ${bearer_id}
    END
    ${state_after}=    Get UE State    10
    ${all_bearers}=    Get Dictionary Values    ${state_after.json()}[bearers]
    FOR    ${bearer}    IN    @{all_bearers}
        Should Not Be True    ${bearer}[active]
    END

TC03 Zatrzymanie Nieaktywnego Transferu Zwraca Blad
    [Documentation]    Próba zatrzymania transferu który nie jest aktywny powinna zwrócić błąd. API zwraca 200 (zachowanie idempotentne - niezgodność ze specyfikacją).
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    10
    ${resp}=    Stop Traffic    10    9
    Status Code Should Be Error    ${resp}

TC04 Po Zatrzymaniu Bearer Jest Nieaktywny
    [Documentation]    Po zatrzymaniu transferu bearer w stanie UE ma flagę active = False.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    Stop Traffic    10    9
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    9
    Should Not Be True    ${bearer}[active]

TC05 Zatrzymanie Transferu Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba zatrzymania transferu dla UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${resp}=    Stop Traffic    99    9
    Status Code Should Be Error    ${resp}

TC06 Zatrzymanie Transferu Na Jednym Bearerze Nie Wplywa Na Drugi
    [Documentation]    Zatrzymanie transferu na jednym bearerze nie dezaktywuje pozostałych bearerów UE.
    [Setup]    Setup API Session
    Attach UE    10
    Add Bearer    10    3
    Start Traffic    10    9    500
    Start Traffic    10    3    500
    Stop Traffic    10    9
    ${state}=    Get UE State    10
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    3
    Should Be True    ${bearer}[active]
