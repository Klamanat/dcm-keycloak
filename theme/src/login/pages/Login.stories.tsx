import type { Meta, StoryObj } from "@storybook/react";
import { createKcPageStory } from "../KcPageStory";

const { KcPageStory } = createKcPageStory({ pageId: "login.ftl" });

const meta: Meta<typeof KcPageStory> = {
    title: "login/Login",
    component: KcPageStory
};
export default meta;

type Story = StoryObj<typeof KcPageStory>;

export const Default: Story = {
    args: {}
};

export const WithRememberMe: Story = {
    args: {
        kcContext: {
            realm: { rememberMe: true }
        }
    }
};

export const WithRegistration: Story = {
    args: {
        kcContext: {
            realm: { registrationAllowed: true }
        }
    }
};
