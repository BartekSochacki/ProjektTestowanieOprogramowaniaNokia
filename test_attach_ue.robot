*** Settings ***
Documentation   Testy funkcjonalności podłączania UE do symulatora EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}         http://localhost:8000
${VALID_UE_ID}      10
${MIN_UE_ID}        1
${MAX_UE_ID}        100
${ZERO_UE_ID}       0
${NEG_UE_ID}        -1
${OUT_OF_RANGE_ID}  101
${DEFAULT_BEARER}   9

*** Keywords ***
Setup API Session
    Create Session    epc    ${BASE_URL}
    POST On Session    epc    /reset    expected_status=any

Attach UE
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Attach UE Without ID
    &{body}=        Create Dictionary
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
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
TC01 Podlaczenie UE Do Sieci Z Poprawnym ID
    [Documentation]    UE może zostać podłączone do sieci z poprawnym ID.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${VALID_UE_ID}
    Status Code Should Be    ${resp}    200

TC02 Podlaczony UE Otrzymuje Domyslny Bearer 9
    [Documentation]    Po podłączeniu UE automatycznie otrzymuje bearer ID=9.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${VALID_UE_ID}
    Status Code Should Be    ${resp}    200
    ${state}=    Get UE State    ${VALID_UE_ID}
    Status Code Should Be    ${state}    200
    ${bearer_str}=    Convert To String    ${DEFAULT_BEARER}
    Dictionary Should Contain Key    ${state.json()}[bearers]    ${bearer_str}

TC03 Ponowne Podlaczenie Juz Podlaczonego UE Zwraca Blad
    [Documentation]    UE już podłączone nie może zostać podłączone ponownie, oczekiwany kod 400.
    [Setup]    Setup API Session
    ${first}=    Attach UE    ${VALID_UE_ID}
    Status Code Should Be    ${first}    200
    ${second}=    Attach UE    ${VALID_UE_ID}
    Status Code Should Be    ${second}    400

TC04 Podlaczenie UE Z ID Minimalnym
    [Documentation]    UE ID = 1 (dolna granica dozwolonego zakresu 1-100) powinno być akceptowane.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${MIN_UE_ID}
    Status Code Should Be    ${resp}    200

TC05 Podlaczenie UE Z ID Maksymalnym
    [Documentation]    UE ID = 100 (górna granica dozwolonego zakresu 1-100) powinno być akceptowane.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${MAX_UE_ID}
    Status Code Should Be    ${resp}    200

TC06 Podlaczenie UE Z ID Zero Zwraca Blad
    [Documentation]    UE ID = 0 jest poza zakresem implementacji (wymaga >= 1), mimo że specyfikacja mówi 0-100.
    [Tags]    known-defect
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${ZERO_UE_ID}
    Status Code Should Be    ${resp}    200

TC07 Podlaczenie UE Z ID Ujemnym Zwraca Blad
    [Documentation]    UE ID = -1 jest poza zakresem, powinien zwrócić 422.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${NEG_UE_ID}
    Status Code Should Be    ${resp}    422

TC08 Podlaczenie UE Z ID Powyzej Zakresu Zwraca Blad
    [Documentation]    UE ID = 101 jest poza zakresem (1-100), powinien zwrócić 422.
    [Setup]    Setup API Session
    ${resp}=    Attach UE    ${OUT_OF_RANGE_ID}
    Status Code Should Be    ${resp}    422

TC09 Podlaczenie UE Bez Podania ID Zwraca Blad
    [Documentation]    Żądanie bez UE ID powinno zwrócić błąd 422.
    [Setup]    Setup API Session
    ${resp}=    Attach UE Without ID
    Status Code Should Be    ${resp}    422
