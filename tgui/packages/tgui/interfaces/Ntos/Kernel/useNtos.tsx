import { useBackend } from '../../../backend';
import { NtosData } from './NtosData';
import { Program } from './Program';

type NtosHook = {
  data: NtosData;
  shutdown: () => void;
  runProgram: (program: Program) => void;
  killProgram: (program: Program) => void;
  act: (action: string, payload: object) => void;
};

export function useNtos<TValue extends NtosData>(): NtosHook {
  const { act, data } = useBackend<TValue>();

  return {
    data,
    shutdown: () => act('shutdown'),
    runProgram: (program: Program) =>
      act('run_program', { name: program.name }),
    killProgram: (program: Program) =>
      act('kill_program', { name: program.name }),
    act: (action, payload = {}) => act(action, payload),
  };
}
