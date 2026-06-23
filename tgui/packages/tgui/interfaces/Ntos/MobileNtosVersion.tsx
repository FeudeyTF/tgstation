import {
  Box,
  Button,
  ColorBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { useNtos } from './Kernel/useNtos';
import { Window } from '../../layouts';
import { resolveAsset } from '../../assets';
import { Program } from './Kernel/Program';

export enum alert_relevancies {
  ALERT_RELEVANCY_SAFE,
  ALERT_RELEVANCY_WARN,
  ALERT_RELEVANCY_PERTINENT,
}

export const MobileNtosVersion = (props) => {
  const { title, width = 575, height = 700 } = props;
  const {
    runProgram,
    killProgram,
    ejectDisk,
    imprintId,
    lightColor,
    toggleLight,
    paiInteract,
    shutdown,
    data,
  } = useNtos();
  const {
    alert_style,
    alert_color,
    alert_name,
    PC_device_theme,
    show_imprint,
    programs = [],
    has_light,
    light_on,
    comp_light_color,
    removable_media = [],
    login,
    proposed_login,
    pai,
    PC_batteryicon,
    PC_batterypercent,
    PC_ntneticon,
    PC_stationdate,
    PC_stationtime,
    PC_programheaders = [],
    PC_lowpower_mode,
  } = data;

  const filtered_programs = programs.filter(
    (program) => program.header_program,
  );

  return (
    <Window title={title} width={width} height={height} theme={PC_device_theme}>
      <Window.Content scrollable>
        <div className="NtosWindow">
          <div className="NtosWindow__header NtosHeader">
            <div className="NtosHeader__left">
              <Box inline bold mr={2}>
                <Button
                  width="26px"
                  lineHeight="22px"
                  textAlign="left"
                  tooltip={PC_stationdate}
                  color="transparent"
                  icon="calendar"
                  tooltipPosition="bottom"
                />
                {PC_stationtime}
              </Box>
              <Box inline italic mr={2} opacity={0.33}>
                {(PC_device_theme === 'syndicate' && 'Syndix') || 'NtOS'}
                {!!PC_lowpower_mode && ' - RUNNING ON LOW POWER MODE'}
              </Box>
            </div>
            <div className="NtosHeader__right">
              {PC_programheaders.map((header) => (
                <Box key={header.icon} inline mr={1}>
                  <img
                    className="NtosHeader__icon"
                    src={resolveAsset(header.icon)}
                  />
                </Box>
              ))}
              <Box inline>
                {PC_ntneticon && (
                  <img
                    className="NtosHeader__icon"
                    src={resolveAsset(PC_ntneticon)}
                  />
                )}
              </Box>
              {!!PC_batteryicon && (
                <Box inline mr={1}>
                  <img
                    className="NtosHeader__icon"
                    src={resolveAsset(PC_batteryicon)}
                  />
                  {PC_batterypercent}
                </Box>
              )}
              {/*!!PC_showexitprogram && (
              <Button
                color="transparent"
                icon="window-minimize-o"
                tooltip="Minimize"
                tooltipPosition="bottom"
                onClick={() => minimizeProgram(program)}
              />
            )}
            {!!PC_showexitprogram && (
              <Button
                color="transparent"
                icon="window-close-o"
                tooltip="Close"
                tooltipPosition="bottom-start"
                onClick={() => killProgram(program)}
              />
            )*/}
              <Button
                textAlign="center"
                color="transparent"
                icon="power-off"
                tooltip="Power off"
                tooltipPosition="bottom-start"
                onClick={() => shutdown()}
              />
            </div>
          </div>
          {Boolean(
            removable_media.length ||
              programs.some((program) => program.header_program),
          ) && (
            <Section>
              <Stack>
                {filtered_programs.map((app) => (
                  <Stack.Item key={app.name}>
                    <Button
                      content={app.desc}
                      icon={app.icon}
                      onClick={() => runProgram(app)}
                    />
                  </Stack.Item>
                ))}
                <Stack.Item right={0}>
                  <Button
                    className={
                      alert_style ===
                      alert_relevancies.ALERT_RELEVANCY_PERTINENT
                        ? 'alertIndicator alertBlink'
                        : 'alertIndicator'
                    }
                    textColor={
                      alert_style === alert_relevancies.ALERT_RELEVANCY_SAFE
                        ? alert_color
                        : '#000000'
                    }
                    backgroundColor={
                      alert_style === alert_relevancies.ALERT_RELEVANCY_SAFE
                        ? '#0000000'
                        : alert_color
                    }
                    tooltip="The current alert level. Indicator becomes more intense when there is a threat, moreso if your department is responsible for handling it."
                  >
                    {alert_name}
                  </Button>
                </Stack.Item>
              </Stack>
              <Stack>
                {removable_media.map((device) => (
                  <Stack.Item key={device} mt={1}>
                    <Button
                      fluid
                      icon="eject"
                      content={device}
                      onClick={() => ejectDisk(device)}
                      disabled={!device}
                    />
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          )}
          <Section
            title="Details"
            buttons={
              <>
                {!!has_light && (
                  <>
                    <Button onClick={() => lightColor()}>
                      <ColorBox color={comp_light_color} />
                    </Button>
                    <Button
                      icon="lightbulb"
                      color={light_on ? 'good' : 'bad'}
                      selected={light_on}
                      onClick={() => toggleLight()}
                    />
                  </>
                )}
                <Button
                  icon="eject"
                  content="Eject ID"
                  disabled={!proposed_login.IDInserted}
                  onClick={() => ejectDisk('ID')}
                />
                {!!show_imprint && (
                  <Button
                    icon="dna"
                    content="Imprint ID"
                    disabled={
                      !proposed_login.IDName ||
                      (proposed_login.IDName === login.IDName &&
                        proposed_login.IDJob === login.IDJob)
                    }
                    onClick={() => imprintId('ID')}
                  />
                )}
              </>
            }
          >
            <Table>
              <Table.Row>
                ID Name:{' '}
                {show_imprint
                  ? login.IDName +
                    ' ' +
                    (proposed_login.IDName ? `(${proposed_login.IDName})` : '')
                  : (proposed_login.IDName ?? '')}
              </Table.Row>
              <Table.Row>
                Assignment:{' '}
                {show_imprint
                  ? login.IDJob +
                    ' ' +
                    (proposed_login.IDJob ? `(${proposed_login.IDJob})` : '')
                  : (proposed_login.IDJob ?? '')}
              </Table.Row>
            </Table>
          </Section>
          {!!pai && <PaiSection interact={paiInteract} />}
          <ProgramsSection
            runProgram={runProgram}
            killProgram={killProgram}
            programs={programs}
          />
        </div>
      </Window.Content>
    </Window>
  );
};

type PaiSectionProps = {
  interact: (option: string) => void;
};

const PaiSection = (props: PaiSectionProps) => {
  const { interact } = props;

  return (
    <Section title="pAI">
      <Table>
        <Table.Row>
          <Table.Cell>
            <Button
              fluid
              icon="eject"
              color="transparent"
              content="Eject pAI"
              onClick={() => interact('eject')}
            />
          </Table.Cell>
        </Table.Row>
        <Table.Row>
          <Table.Cell>
            <Button
              fluid
              icon="cat"
              color="transparent"
              content="Configure pAI"
              onClick={() => interact('interact')}
            />
          </Table.Cell>
        </Table.Row>
      </Table>
    </Section>
  );
};

type ProgramsSectionProps = {
  runProgram: (program: any) => void;
  killProgram: (program: any) => void;
  programs: Program[];
};

const ProgramsSection = (props: ProgramsSectionProps) => {
  const { runProgram, killProgram, programs } = props;
  // add the program filename to this list to have it excluded from the main menu program list table
  const filtered_programs = programs.filter(
    (program) => !program.header_program,
  );

  return (
    <Section title="Programs">
      <Table>
        {filtered_programs.map((program) => (
          <Table.Row key={program.name}>
            <Table.Cell>
              <Button
                fluid
                color={program.alert ? 'yellow' : 'transparent'}
                icon={program.icon}
                content={program.desc}
                onClick={() => runProgram(program)}
              />
            </Table.Cell>
            <Table.Cell collapsing width="18px">
              {!!program.running && (
                <Button
                  color="transparent"
                  icon="times"
                  tooltip="Close program"
                  tooltipPosition="left"
                  onClick={() => killProgram(program)}
                />
              )}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
