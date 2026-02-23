import { BooleanLike } from '../../common/react';
import { capitalizeAll } from '../../common/string';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export type AutolatheData = {
  manufacturer: string;
  disabled: BooleanLike;
  material_efficiency: number;
  build_time: number;
  materials: Material[];
  total_material_amount: number;
  total_material_capacity: number;
  recipes: Recipe[];
  categories: string[];
  queue: QueueItem[];
  currently_printing: string;
};

type Material = {
  material: string;
  stored: number;
};

type Recipe = {
  name: string;
  category: string;
  resources: string;
  max_sheets: number;
  sheets: number;
  can_make: BooleanLike;
  recipe: string;
  security_level: string;
  hack_only: BooleanLike;
  enabled: BooleanLike;
  build_time: number;
};

type QueueItem = {
  ref: string;
  order: string;
  path: string;
  multiplier: number;
  build_time: number;
  progress: number;
  remaining_time: number;
};

export const Autolathe = (props, context) => {
  const { act, data } = useBackend<AutolatheData>(context);
  const [tab, setTab] = useLocalState(context, 'tab', 'All');

  return (
    <Window resizable theme={data.manufacturer} width="1000" height="700">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section fill title="Materials">
              <LabeledList>
                <LabeledList.Item label="Total Materials">
                  <ProgressBar
                    value={data.total_material_capacity}
                    minValue={0}
                    maxValue={data.total_material_capacity}
                    ranges={{
                      good: [
                        data.total_material_capacity * 0.75,
                        data.total_material_capacity,
                      ],
                      average: [
                        data.total_material_capacity * 0.3,
                        data.total_material_capacity * 0.75,
                      ],
                      bad: [0, data.total_material_capacity * 0.3],
                    }}
                  >
                    {data.total_material_capacity +
                      '/' +
                      data.total_material_capacity +
                      ' cm³'}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item>
                  {data.materials.length > 0 && (
                    <Collapsible title="Materials">
                      <LabeledList>
                        {data.materials.map((material) => (
                          <MaterialRow
                            key={material.material}
                            material={material}
                            materialsmax={data.total_material_capacity}
                            onRelease={(amount) =>
                              act('materialEject', {
                                materialName: material.material,
                                amount: material.stored,
                              })
                            }
                          />
                        ))}
                      </LabeledList>
                    </Collapsible>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack>
            <Stack.Item width={'175px'}>
              <Tabs vertical>
                {data.categories.map((category) => (
                  <Tabs.Tab
                    textAlign="center"
                    selected={category === tab}
                    key={category}
                    onClick={() => setTab(category)}
                  >
                    {category}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Stack.Item>
            <Stack.Item grow>
              {tab ? <CategoryData /> : 'No category selected.'}
            </Stack.Item>
            <Stack.Item grow>
              <QueueData />
            </Stack.Item>
          </Stack>
        </Stack>
      </Window.Content>
    </Window>
  );
};

export const CategoryData = (props, context) => {
  const { act, data } = useBackend<AutolatheData>(context);
  const [tab, setTab] = useLocalState(context, 'tab', 'All');
  const [searchTerm, setSearchTerm] = useLocalState<string>(
    context,
    `searchTerm`,
    ``,
  );
  const [amount, setAmount] = useLocalState(context, 'amount', 1);

  return (
    <Section
      fill
      title={tab}
      buttons={
        <Input
          autoFocus
          autoSelect
          placeholder="Search by name"
          maxLength={512}
          onInput={(e, value) => {
            setSearchTerm(value);
          }}
          value={searchTerm}
        />
      }
    >
      <Table collapsing>
        <Table.Row header>
          <Table.Cell>Recipe</Table.Cell>
          <Table.Cell>Resources</Table.Cell>
        </Table.Row>
        {data.recipes
          .filter(
            (c) => c.name?.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1,
          )
          .map((recipe) =>
            recipe.category === tab || tab === 'All' ? (
              <Table.Row>
                <Table.Cell py={0.25}>
                  <Button
                    content={
                      <Box bold color={recipe.hack_only ? 'red' : ''}>
                        {capitalizeAll(recipe.name)}
                      </Box>
                    }
                    tooltip={
                      !recipe.enabled
                        ? 'Security Level Needed: ' + recipe.security_level
                        : ''
                    }
                    className={
                      !recipe.enabled || recipe.can_make
                        ? 'color-disabled'
                        : 'color-default'
                    }
                    backgroundColor={
                      !recipe.enabled || recipe.can_make ? '#9c0000' : null
                    }
                    textColor={
                      !recipe.enabled || recipe.can_make ? '#9e9e9e' : null
                    }
                    onClick={() =>
                      !recipe.enabled || recipe.can_make
                        ? null
                        : act('make', { multiplier: 1, recipe: recipe.recipe })
                    }
                  />
                  {recipe.max_sheets ? (
                    <>
                      {' '}
                      <Button
                        content={
                          <Box bold color={recipe.hack_only ? 'red' : ''}>
                            [x5]
                          </Box>
                        }
                        className={
                          !recipe.enabled || recipe.can_make
                            ? 'color-disabled'
                            : 'color-default'
                        }
                        backgroundColor={
                          !recipe.enabled || recipe.can_make ? '#9c0000' : null
                        }
                        textColor={
                          !recipe.enabled || recipe.can_make ? '#9e9e9e' : null
                        }
                        onClick={() =>
                          !recipe.enabled || recipe.can_make
                            ? null
                            : act('make', {
                                multiplier: 5,
                                recipe: recipe.recipe,
                              })
                        }
                      />
                      <Button
                        content={
                          <Box bold color={recipe.hack_only ? 'red' : ''}>
                            [x10]
                          </Box>
                        }
                        className={
                          !recipe.enabled || recipe.can_make
                            ? 'color-disabled'
                            : 'color-default'
                        }
                        backgroundColor={
                          !recipe.enabled || recipe.can_make ? '#9c0000' : null
                        }
                        textColor={
                          !recipe.enabled || recipe.can_make ? '#9e9e9e' : null
                        }
                        onClick={() =>
                          !recipe.enabled || recipe.can_make
                            ? null
                            : act('make', {
                                multiplier: 10,
                                recipe: recipe.recipe,
                              })
                        }
                      />
                      <Button
                        content={
                          <Box bold color={recipe.hack_only ? 'red' : ''}>
                            [x{recipe.max_sheets}]
                          </Box>
                        }
                        className={
                          !recipe.enabled || recipe.can_make
                            ? 'color-disabled'
                            : 'color-default'
                        }
                        backgroundColor={
                          !recipe.enabled || recipe.can_make ? '#9c0000' : null
                        }
                        textColor={
                          !recipe.enabled || recipe.can_make ? '#9e9e9e' : null
                        }
                        onClick={() =>
                          !recipe.enabled || recipe.can_make
                            ? null
                            : act('make', {
                                multiplier: recipe.max_sheets,
                                recipe: recipe.recipe,
                              })
                        }
                      />
                    </>
                  ) : (
                    ''
                  )}
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    color="transparent"
                    tooltip={
                      <>
                        <div>{recipe.resources}</div>
                        <div>{recipe.build_time} seconds</div>
                      </>
                    }
                    icon="question"
                  />
                </Table.Cell>
              </Table.Row>
            ) : (
              ''
            ),
          )}
      </Table>
    </Section>
  );
};

export const QueueData = (props, context) => {
  const { act, data } = useBackend<AutolatheData>(context);

  return (
    <Section fill title="Queue">
      <LabeledList>
        {data.queue?.length ? (
          data.queue.map((queue_item) => (
            <LabeledList.Item
              key={queue_item.ref}
              label={capitalizeAll(queue_item.order)}
            >
              <ProgressBar
                minValue={0}
                maxValue={queue_item.build_time}
                value={queue_item.progress}
                ranges={{
                  good: [queue_item.build_time * 0.5, queue_item.build_time],
                  average: [
                    queue_item.build_time * 0.25,
                    queue_item.build_time * 0.5,
                  ],
                  bad: [0, queue_item.build_time * 0.25],
                }}
              >
                {queue_item.remaining_time / 10} seconds
                <Button
                  icon="cancel"
                  color="transparent"
                  disabled={queue_item.ref === data.currently_printing}
                  onClick={() => act('remove', { ref: queue_item.ref })}
                />
              </ProgressBar>
            </LabeledList.Item>
          ))
        ) : (
          <NoticeBox>The queue is empty.</NoticeBox>
        )}
      </LabeledList>
    </Section>
  );
};

const MaterialRow = (props, context) => {
  const { material, materialsmax, onRelease } = props;

  const [amount, setAmount] = useLocalState(
    context,
    'amount' + material.name,
    1,
  );

  const amountAvailable = Math.floor(material.amount);
  return (
    <LabeledList.Item key={material.id}>
      <Table width="100%">
        <Table.Row>
          <Table.Cell>{capitalizeAll(material.name)}</Table.Cell>
          <Table.Cell textAlign="right">
            <Box mr={2} color="label" inline>
              {material.sheets_amount} sheets
            </Box>
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            <Button
              disabled={material.sheets_amount < 1}
              content="x1"
              onClick={() => onRelease(1)}
            />
            <Button
              disabled={material.sheets_amount < 5}
              content="x5"
              onClick={() => onRelease(5)}
            />
            <Button
              disabled={material.sheets_amount < 10}
              content="x10"
              onClick={() => onRelease(10)}
            />
            <Button
              disabled={material.sheets_amount < 25}
              content="x25"
              onClick={() => onRelease(25)}
            />
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            <NumberInput
              width="32px"
              step={1}
              stepPixelSize={5}
              minValue={1}
              maxValue={material.sheets_amount}
              value={amount}
              onChange={(e, value) => setAmount(value)}
            />
            <Button
              disabled={material.sheets_amount < 1}
              content="Release"
              onClick={() => onRelease(amount)}
            />
          </Table.Cell>
        </Table.Row>
        <Table.Row>
          <Table.Cell colspan="4">
            <ProgressBar
              style={{
                transform: 'scaleX(-1) scaleY(1)',
              }}
              value={materialsmax - material.mineral_amount}
              maxValue={materialsmax}
              color="black"
              backgroundColor={material.matcolour}
            >
              <div style={{ transform: 'scaleX(-1)' }}>
                {material.mineral_amount + ' cm³'}
              </div>
            </ProgressBar>
          </Table.Cell>
        </Table.Row>
      </Table>
    </LabeledList.Item>
  );
};
